﻿using Engine.Models;
using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;

namespace ValidationWeb.Services
{
    public class RulesEngineService : IRulesEngineService
    {
        protected readonly ValidationPortalDbContext _dbContext;
        protected readonly IRulesEngineConfigurationValues _engineConfig;
        protected readonly Model _engineObjectModel;
        protected readonly IAppUserService _appUserService;
        protected readonly IEdOrgService _edOrgService;
        protected readonly ISchoolYearService _schoolYearService;
        protected readonly ILoggingService _loggingService;

        public RulesEngineService(
            IAppUserService appUserService,
            IEdOrgService edOrgService,
            ISchoolYearService schoolYearService,
            IRulesEngineConfigurationValues engineConfig,
            ILoggingService loggingService,
            ValidationPortalDbContext dbContext,
            Model engineObjectModel
            )
        {
            _dbContext = dbContext;
            _appUserService = appUserService;
            _edOrgService = edOrgService;
            _schoolYearService = schoolYearService;
            _loggingService = loggingService;
            _engineConfig = engineConfig;
            _engineObjectModel = engineObjectModel;
        }

        public ValidationReportSummary RunEngine(string fourDigitOdsDbYear, string collectionId)
        {
            ValidationReportSummary newReportSummary = null;
            using (var _odsRawDbContext = new RawOdsDbContext(fourDigitOdsDbYear))
            {
                _loggingService.LogDebugMessage($"Connecting to the Ed Fi ODS {fourDigitOdsDbYear} to run the Rules Engine. Submitting the RulesValidation run ID.");
                // Run the rules - This code is adapted from an example in the Rule Engine project.
                #region Add a new execution of the Validation Engine to the ODS database, (required by the Engine) and get an ID back representing this execution.
                var newRuleValidationExecution = new RuleValidation { CollectionId = collectionId };
                _odsRawDbContext.RuleValidations.Add(newRuleValidationExecution);
                _odsRawDbContext.SaveChanges();
                _loggingService.LogDebugMessage($"Successfully submitted RuleValidationId {newRuleValidationExecution.RuleValidationId.ToString()} to the Rules Engine database table.");
                #endregion Add a new execution of the Validation Engine to the ODS database, (required by the Engine) and get an ID back representing this execution.

                #region Add a new execution of the Validation Engine to the Validation database, (required by the Portal) and get an ID back representing this execution.
                newReportSummary = new ValidationReportSummary
                {
                    Collection = collectionId,
                    CompletedWhen = null,
                    ErrorCount = null,
                    WarningCount = null,
                    TotalCount = 0,
                    Id = newRuleValidationExecution.RuleValidationId,
                    EdOrgId = _appUserService.GetSession().FocusedEdOrgId,
                    SchoolYear = _schoolYearService.GetSubmittableSchoolYears().FirstOrDefault(sy => sy.EndYear == fourDigitOdsDbYear),
                    InitiatedBy = _appUserService.GetUser().FullName,
                    RequestedWhen = DateTime.UtcNow,
                    Status = "In Progress"
                };
                _dbContext.ValidationReportSummaries.Add(newReportSummary);
                _dbContext.SaveChanges();
                _loggingService.LogDebugMessage($"Successfully submitted Validation Report Summary ID {newReportSummary.Id} to the Validation Portal database for Rules Validation Run {newRuleValidationExecution.RuleValidationId.ToString()}.");
                #endregion Add a new execution of the Validation Engine to the Validation database, (required by the Portal) and get an ID back representing this execution.

                #region Now, store each Ruleset ID and Rule ID that the engine will run. Save it in the Engine database.
                _loggingService.LogDebugMessage($"Getting the rules to run for the chosen collection {collectionId}.");
                var rules = _engineObjectModel.GetRules(collectionId).ToArray();
                var ruleComponents = rules.SelectMany(r => r.Components.Distinct().Select(c => new { r.RulesetId, r.RuleId, Component = c }));
                foreach (var singleRuleNeedingToBeValidated in ruleComponents)
                {
                    _odsRawDbContext.RuleValidationRuleComponents.Add(new RuleValidationRuleComponent
                    {
                        RuleValidationId = newRuleValidationExecution.RuleValidationId,
                        RulesetId = singleRuleNeedingToBeValidated.RulesetId,
                        RuleId = singleRuleNeedingToBeValidated.RuleId,
                        Component = singleRuleNeedingToBeValidated.Component
                    });
                }
                _odsRawDbContext.SaveChanges();
                _loggingService.LogDebugMessage($"Saved the rules to run for the chosen collection {collectionId}.");
                #endregion Now, store each Ruleset ID and Rule ID that the engine will run. Save it in the Engine database.

                #region The ValidationReportDetails is one-for-one with the ValidationReportSummary - it should be refactored away. It contains the error/warning details.
                _loggingService.LogDebugMessage($"Adding additional Validation Report details to the Validation Portal database for EdOrgID {newReportSummary.EdOrgId}.");
                var newReportDetails = new ValidationReportDetails
                {
                    CollectionName = collectionId,
                    DistrictName = $"{_edOrgService.GetEdOrgById(newReportSummary.EdOrgId, newReportSummary.SchoolYear.Id).OrganizationName} ({newReportSummary.EdOrgId.ToString()})",
                    ValidationReportSummaryId = newReportSummary.Id,
                    SchoolYearId = newReportSummary.SchoolYear.Id
                };
                _dbContext.ValidationReportDetails.Add(newReportDetails);
                _dbContext.SaveChanges();
                _loggingService.LogDebugMessage($"Successfully added additional Validation Report details to the Validation Portal database for EdOrgID {newReportSummary.EdOrgId}.");
                #endregion The ValidationReportDetails is one-for-one with the ValidationReportSummary - it should be refactored away. It contains the error/warning details.

                #region Execute each individual rule.
                List<RulesEngineExecutionException> rulesEngineExecutionExceptions = new List<RulesEngineExecutionException>();
                foreach (var rule in rules)
                {
                    try
                    {
                        // By default, rules are run against ALL districts in the Ed Fi ODS. This line filters for multi-district/multi-tenant ODS's.
                        rule.AddDistrictWhereFilter(newReportSummary.EdOrgId);

                        _loggingService.LogDebugMessage($"Executing Rule {rule.RuleId}.");
                        _loggingService.LogDebugMessage($"Executing Rule SQL {rule.Sql}.");
                        var detailParams = new List<SqlParameter> { new SqlParameter("@RuleValidationId", newRuleValidationExecution.RuleValidationId) };
                        detailParams.AddRange(_engineObjectModel.GetParameters(collectionId).Select(x => new SqlParameter(x.ParameterName, x.Value)));
                        _odsRawDbContext.Database.CommandTimeout = 60;
                        var result = _odsRawDbContext.Database.ExecuteSqlCommand(rule.ExecSql, detailParams.ToArray());
                        _loggingService.LogDebugMessage($"Executing Rule {rule.RuleId} rows affected = {result}.");

                        #region Record the results of this rule in the Validation Portal database, accompanied by more detailed information.
                        PopulateErrorDetailsFromViews(rule, _odsRawDbContext, newRuleValidationExecution.RuleValidationId, newReportDetails.Id);
                        #endregion Record the results of this rule in the Validation Portal database, accompanied by more detailed information.
                    }
                    catch(Exception ex)
                    {
                        rulesEngineExecutionExceptions.Add(new RulesEngineExecutionException
                        {
                            RuleId = rule.RuleId,
                            Sql = rule.Sql,
                            ExecSql = rule.ExecSql,
                            DataSourceName = $"Database Server: {_odsRawDbContext.Database.Connection.DataSource}{Environment.NewLine} Database: {_odsRawDbContext.Database.Connection.Database}",
                            ChainedErrorMessages = ex.ChainInnerExceptionMessages()
                        });
                    }
                }
                #endregion Execute each individual rule.

                _loggingService.LogDebugMessage($"Counting errors and warnings.");
                newReportSummary.CompletedWhen = DateTime.UtcNow;
                newReportSummary.ErrorCount = _odsRawDbContext.RuleValidationDetails.Where(rvd => rvd.RuleValidation.RuleValidationId == newRuleValidationExecution.RuleValidationId && rvd.IsError).Count();
                newReportSummary.WarningCount = _odsRawDbContext.RuleValidationDetails.Where(rvd => rvd.RuleValidation.RuleValidationId == newRuleValidationExecution.RuleValidationId && !rvd.IsError).Count();
                var hasExecutionErrors = (rulesEngineExecutionExceptions.Count > 0);
                newReportSummary.Status = hasExecutionErrors ? $"Completed - {rulesEngineExecutionExceptions.Count} rules did not execute, ask an administrator to check the log for errors, Report Summary Number {newReportSummary.Id.ToString()}" : "Completed";
                _loggingService.LogDebugMessage($"Saving status {newReportSummary.Status}.");

                // Log Execution Errors
                _loggingService.LogErrorMessage(GetLogExecutionErrorsMessage(rulesEngineExecutionExceptions, newReportSummary.Id));

                newReportDetails.CompletedWhen = newReportDetails.CompletedWhen ?? DateTime.UtcNow;
                _dbContext.SaveChanges();
                _loggingService.LogDebugMessage($"Saved status.");
            }
            return newReportSummary;
        }

        protected string GetLogExecutionErrorsMessage(IList<RulesEngineExecutionException> rulesEngineExecutionExceptions, long reportId)
        {
                var logMessageBuilder = new StringBuilder();
                logMessageBuilder.AppendLine("=================================================");
                logMessageBuilder.AppendLine($"Rules Engine Execution Errors Reported for Validation Report Summary # {reportId.ToString()}:");
                foreach (var execError in rulesEngineExecutionExceptions)
                {
                    logMessageBuilder.AppendLine();
                    logMessageBuilder.AppendLine($"Rule ID: {execError.RuleId ?? "null"}");
                    logMessageBuilder.AppendLine($"Server and Database: {execError.DataSourceName ?? "null"}");
                    logMessageBuilder.AppendLine($"SQL: {execError.Sql ?? "null"}");
                    logMessageBuilder.AppendLine($"Executed SQL: {execError.ExecSql ?? "null"}");
                    logMessageBuilder.AppendLine($"Chained Error Message and Stack Trace:");
                    logMessageBuilder.AppendLine(execError.ChainedErrorMessages ?? "null");
                }
                logMessageBuilder.AppendLine("=================================================");
            return logMessageBuilder.ToString();
        }

        public List<Collection> GetCollections()
        {
            return _engineObjectModel.Collections.ToList();
        }

        /// <summary>
        /// For a single rule, on a single execution of the Rules Engine, records the resulting errors and warnings accompanied by enhanced information.
        /// </summary>
        /// <param name="rule">The single rule whose corresponding errors and warnings will be recorded in the Validation Portal's Database.</param>
        /// <param name="rawOdsContext">A connection to the Ed Fi ODS database from which details about the error and the entity the error relates to. 
        /// Used as a source to fill in details about Individual errors and warnings.</param>
        /// <param name="rulesExecutionId">The single execution of the Rules Engine which serves as the scope of the paticular errors and warnings that will be
        /// transferred to the Validation Portal database. This ID is used by the Rules engine database.</param>
        /// <param name="reportDetailId">The single execution of the Rules Engine which serves as the scope of the paticular errors and warnings that will be
        /// transferred to the Validation Portal database. This ID is used by the Validation Portal database.</param>
        private void PopulateErrorDetailsFromViews(Rule rule, RawOdsDbContext rawOdsContext, long rulesExecutionId, int reportDetailId)
        {
            _loggingService.LogDebugMessage($"Preparing to populate the error information for rule {rule.RuleId} to the Validation Portal database.");
            try
            {
                var errorSummaries = new List<ValidationErrorSummary>();

                // Retrieve what the Rules Engine recorded - errors or warnings for this particular rule, on this particular execution.
                var queryResults = rawOdsContext.RuleValidationDetails.Where(rvd => rvd.RuleValidationId == rulesExecutionId && rvd.RuleId == rule.RuleId);
                _loggingService.LogDebugMessage($"Successfully retrieved results for rule {rule.RuleId} from the Ed Fi ODS database Rules Validation tables. Retrieving additional information.");
                var conn = rawOdsContext.Database.Connection;
                try
                {
                    conn.Open();
                    var studentQueryCmd = conn.CreateCommand();
                    studentQueryCmd.CommandType = System.Data.CommandType.Text;
                    studentQueryCmd.CommandText = StudentDataFromId.StudentDataQueryFromId;
                    studentQueryCmd.Parameters.Add(new SqlParameter("@student_unique_id", System.Data.SqlDbType.NVarChar, 32));

                    foreach (var queryResult in queryResults.ToArray())
                    {
                        studentQueryCmd.Parameters["@student_unique_id"].Value = queryResult.Id.ToString();
                        var singleStudentData = new List<StudentDataFromId>();
                        using (var reader = studentQueryCmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var entryDateValue = System.Convert.IsDBNull(reader[StudentDataFromId.EntryDateColumnName]) ? (DateTime?)null : Convert.ToDateTime(reader[StudentDataFromId.EntryDateColumnName]);
                                var exitWithdrawDateValue = System.Convert.IsDBNull(reader[StudentDataFromId.ExitWithdrawDateColumnName]) ? (DateTime?)null : Convert.ToDateTime(reader[StudentDataFromId.ExitWithdrawDateColumnName]);
                                singleStudentData.Add(new StudentDataFromId
                                {
                                    EntryDate = entryDateValue,
                                    ExitWithdrawDate = exitWithdrawDateValue,
                                    FirstName = reader[StudentDataFromId.FirstNameColumnName].ToString(),
                                    GradeLevel = reader[StudentDataFromId.GradeLevelColumnName].ToString(),
                                    LastSurname = reader[StudentDataFromId.LastSurnameColumnName].ToString(),
                                    MiddleName = reader[StudentDataFromId.MiddleNameColumnName].ToString(),
                                    NameOfInstitution = reader[StudentDataFromId.NameOfInstitutionColumnName].ToString(),
                                    SchoolId = reader[StudentDataFromId.SchoolIdColumnName].ToString(),
                                });
                            }
                        }

                        _loggingService.LogDebugMessage($"Additional info for one student error record retrieved from the ODS Rules Engine database table {rule.RuleId}.");

                        // var sqlCountStatement = $"SELECT Count([Id]) FROM [rules].[{componentName}]";

                        #region Record the error (warning) with additional details taken from the ODS database.
                        errorSummaries.Add(new ValidationErrorSummary
                        {
                            StudentUniqueId = queryResult.Id.ToString(),
                            StudentFullName = StudentDataFromId.GetStudentFullName(singleStudentData),
                            SeverityId = (queryResult.IsError ? (int)ErrorSeverity.Error : (int)ErrorSeverity.Warning),
                            Component = rule.Components[0],
                            ErrorCode = rule.RuleId,
                            ErrorText = queryResult.Message,
                            ValidationReportDetailsId = reportDetailId,
                            ErrorEnrollmentDetails = new HashSet<ValidationErrorEnrollmentDetail>(singleStudentData.Select(
                                    ssd => new ValidationErrorEnrollmentDetail
                                    {
                                        School = ssd.NameOfInstitution,
                                        SchoolId = ssd.SchoolId,
                                        Grade = ssd.GradeLevel,
                                        DateEnrolled = ssd.EntryDate,
                                        DateWithdrawn = ssd.ExitWithdrawDate
                                    }
                                )
                            ),
                        });
                        _loggingService.LogDebugMessage($"A record was added to the Validational Portal, but not yet committed.");

                        #endregion Record the error (warning) with additional details taken from the ODS database.
                    }
                }
                catch (Exception ex)
                {
                    _loggingService.LogErrorMessage($"While reading student data to add to error/warning information during an execution of the validation engine, and error occurred: {ex.ChainInnerExceptionMessages()}");
                }
                finally
                {
                    if (conn != null && conn.State != System.Data.ConnectionState.Closed)
                    {
                        try
                        {
                            conn.Close();
                        }
                        catch (Exception) { }
                    }
                }
                _dbContext.ValidationErrorSummaries.AddRange(errorSummaries);
                _dbContext.SaveChanges();
                _loggingService.LogDebugMessage($"Successfully committed all additional error information for students found with issues referring to rule {rule.RuleId}.");
            }
            catch (Exception ex)
            {
                _loggingService.LogErrorMessage($"Error when compiling details of validation error {rule.RuleId ?? string.Empty}: {ex.ChainInnerExceptionMessages()}");
            }
        }
    }
}