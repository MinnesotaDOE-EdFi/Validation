﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ValidationWeb.Services
{
    public class ValidationResultsService : IValidationResultsService
    {
        private ErrorSeverityLookup anError = ValidationPortalDbMigrationConfiguration.ErrorSeverityLookups.First(sev => sev.CodeValue == ErrorSeverity.Error.ToString());
        private ErrorSeverityLookup aWarning = ValidationPortalDbMigrationConfiguration.ErrorSeverityLookups.First(sev => sev.CodeValue == ErrorSeverity.Warning.ToString());
        protected readonly ValidationPortalDbContext _portalDbContext;
        public ValidationResultsService(ValidationPortalDbContext portalDbContext)
        {
            _portalDbContext = portalDbContext;
        }

        public ValidationReportDetails GetValidationReportDetails(int validationReportId)
        {
            switch (validationReportId)
            {
                case 1:
                    return new ValidationReportDetails
                    {
                        CollectionName = "End of Year Collection",
                        CompletedWhen = new DateTime(2018, 4, 26, 15, 1, 44),
                        DistrictName = "North St. Paul-Maplewood School District",
                        ErrorSummaries = new ValidationErrorSummary[]
                        {
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 0, StudentUniqueId = "11173649", Title = "Ms.", FirstName = "Maria", MiddleName = "Ana", LastName = "Valle-Smith" },
                                School = "Eagle Point Elementary",
                                Grade = "Four",
                                ErrorCode = "2",
                                ErrorText = "Student grade level is significantly different from expected based on age.",
                                Severity = anError
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Demographics",
                                Student = new Student { Id = 1, StudentUniqueId = "22292332", Title = "Mr.", FirstName = "Jonathan", MiddleName = "Francois", LastName = "Delacroix", Suffix = "III" },
                                School = "Eagle Point Elementary",
                                Grade = "Six",
                                ErrorCode = "42",
                                ErrorText = "Student race changed from previous years.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 2, StudentUniqueId = "3333332", Title = "Ms.", FirstName = "Judy", LastName = "Garland" },
                                School = "Eagle Point Elementary",
                                Grade = "Seven",
                                ErrorCode = "9",
                                ErrorText = "Parent/guardian record missing.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 3, StudentUniqueId = "44444432", Title = "Mr.", FirstName = "John", MiddleName = "X", LastName = "Glenn", Suffix = "Jr." },
                                School = "Eagle Point Elementary",
                                Grade = "Eight",
                                ErrorCode = "16",
                                ErrorText = "Student address zip code not valid.",
                                Severity = anError
                            }
                        }
                    };
                case 2:
                    return new ValidationReportDetails
                    {
                        CollectionName = "End of Year Collection",
                        CompletedWhen = new DateTime(2018, 4, 26, 15, 1, 44),
                        DistrictName = "North St. Paul-Maplewood School District",
                        ErrorSummaries = new ValidationErrorSummary[]
                        {
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 10, StudentUniqueId = "101010101010", Title = "Ms.", FirstName = "Sandy", MiddleName = "Yen", LastName = "Hui" },
                                School = "Eagle Point Elementary",
                                Grade = "Four",
                                ErrorCode = "2",
                                ErrorText = "Student grade level is significantly different from expected based on age.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Demographics",
                                Student = new Student { Id = 12, StudentUniqueId = "0012001212", Title = "Mr.", FirstName = "Albert", MiddleName = "S", LastName = "Lindt", Suffix = "Jr." },
                                School = "Eagle Point Elementary",
                                Grade = "Six",
                                ErrorCode = "42",
                                ErrorText = "Student race changed from previous years.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 41, StudentUniqueId = "41414141414", Title = "Mr.", FirstName = "Vin", LastName = "Verdi" },
                                School = "Eagle Point Elementary",
                                Grade = "Seven",
                                ErrorCode = "9",
                                ErrorText = "Parent/guardian record missing.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 55, StudentUniqueId = "22292332", Title = "Mr.", FirstName = "James", MiddleName = "Q", LastName = "Brown" },
                                School = "Eagle Point Elementary",
                                Grade = "Eight",
                                ErrorCode = "16",
                                ErrorText = "Student address zip code not valid.",
                                Severity = aWarning
                            }
                        }
                    };
                default:
                    return new ValidationReportDetails
                    {
                        CollectionName = "End of Year Collection",
                        CompletedWhen = new DateTime(2018, 4, 26, 15, 1, 44),
                        DistrictName = "North St. Paul-Maplewood School District",
                        ErrorSummaries = new ValidationErrorSummary[]
                        {
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 10, StudentUniqueId = "101010101010", Title = "Ms.", FirstName = "Sandy", MiddleName = "Yen", LastName = "Hui" },
                                School = "Eagle Point Elementary",
                                Grade = "Four",
                                ErrorCode = "2",
                                ErrorText = "Student grade level is significantly different from expected based on age.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Demographics",
                                Student = new Student { Id = 12, StudentUniqueId = "0012001212", Title = "Mr.", FirstName = "Albert", MiddleName = "S", LastName = "Lindt", Suffix = "Jr." },
                                School = "Eagle Point Elementary",
                                Grade = "Six",
                                ErrorCode = "42",
                                ErrorText = "Student race changed from previous years.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 41, StudentUniqueId = "41414141414", Title = "Mr.", FirstName = "Vin", LastName = "Verdi" },
                                School = "Eagle Point Elementary",
                                Grade = "Seven",
                                ErrorCode = "9",
                                ErrorText = "Parent/guardian record missing.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 55, StudentUniqueId = "22292332", Title = "Mr.", FirstName = "James", MiddleName = "Q", LastName = "Brown" },
                                School = "Eagle Point Elementary",
                                Grade = "Eight",
                                ErrorCode = "16",
                                ErrorText = "Student address zip code not valid.",
                                Severity = aWarning
                            }
                        }
                    };
            }
        }

        public List<ValidationReportSummary> GetValidationReportSummaries(string edOrgId)
        {
            return _portalDbContext.ValidationReportSummaries.Where(vrs => vrs.EdOrgId == edOrgId).ToList();
        }

        public List<ValidationErrorSummary> GetValidationErrorSummaryTableData(int validationReportSummaryId)
        {
            var anError = ValidationPortalDbMigrationConfiguration.ErrorSeverityLookups.First(sev => sev.CodeValue == ErrorSeverity.Error.ToString());
            var aWarning = ValidationPortalDbMigrationConfiguration.ErrorSeverityLookups.First(sev => sev.CodeValue == ErrorSeverity.Warning.ToString());

            List<ValidationErrorSummary> errorSummaryList;

            switch (validationReportSummaryId)
            {
                case 1:
                    errorSummaryList = new List<ValidationErrorSummary>
                    {
                         new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 0, StudentUniqueId = "11173649", Title = "Ms.", FirstName = "Maria", MiddleName = "Ana", LastName = "Valle-Smith" },
                                School = "Eagle Point Elementary",
                                Grade = "Four",
                                ErrorCode = "2",
                                ErrorText = "Student grade level is significantly different from expected based on age.",
                                Severity = anError
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Demographics",
                                Student = new Student { Id = 1, StudentUniqueId = "22292332", Title = "Mr.", FirstName = "Jonathan", MiddleName = "Francois", LastName = "Delacroix", Suffix = "III" },
                                School = "Eagle Point Elementary",
                                Grade = "Six",
                                ErrorCode = "42",
                                ErrorText = "Student race changed from previous years.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 2, StudentUniqueId = "3333332", Title = "Ms.", FirstName = "Judy", LastName = "Garland" },
                                School = "Eagle Point Elementary",
                                Grade = "Seven",
                                ErrorCode = "9",
                                ErrorText = "Parent/guardian record missing.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 3, StudentUniqueId = "44444432", Title = "Mr.", FirstName = "John", MiddleName = "X", LastName = "Glenn", Suffix = "Jr." },
                                School = "Eagle Point Elementary",
                                Grade = "Eight",
                                ErrorCode = "16",
                                ErrorText = "Student address zip code not valid.",
                                Severity = anError
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Soemtihng",
                                Student = new Student { Id = 3, StudentUniqueId = "5456", Title = "Ms.12", FirstName = "Judy", LastName = "Garland" },
                                School = "Eagle Point Elementary",
                                Grade = "Seven",
                                ErrorCode = "9",
                                ErrorText = "Parent/guardian record missing.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Beep Boop",
                                Student = new Student { Id = 3, StudentUniqueId = "44444432", Title = "Mr.", FirstName = "John", MiddleName = "X", LastName = "Glenn", Suffix = "Jr." },
                                School = "Eagle Point Elementary",
                                Grade = "NINE",
                                ErrorCode = "16",
                                ErrorText = "Student address zip code not valid.",
                                Severity = anError
                            }
                    };
                    break;
                case 2:
                    errorSummaryList = new List<ValidationErrorSummary>
                        { new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 10, StudentUniqueId = "101010101010", Title = "Ms.", FirstName = "Sandy", MiddleName = "Yen", LastName = "Hui" },
                                School = "Eagle Point Elementary",
                                Grade = "Four",
                                ErrorCode = "2",
                                ErrorText = "Student grade level is significantly different from expected based on age.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Demographics",
                                Student = new Student { Id = 12, StudentUniqueId = "0012001212", Title = "Mr.", FirstName = "Albert", MiddleName = "S", LastName = "Lindt", Suffix = "Jr." },
                                School = "Eagle Point Elementary",
                                Grade = "Six",
                                ErrorCode = "42",
                                ErrorText = "Student race changed from previous years.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 41, StudentUniqueId = "41414141414", Title = "Mr.", FirstName = "Vin", LastName = "Verdi" },
                                School = "Eagle Point Middle School",
                                Grade = "Seven",
                                ErrorCode = "9",
                                ErrorText = "Parent/guardian record missing.",
                                Severity = aWarning
                            },
                            new ValidationErrorSummary
                            {
                                Component = "Student Enrollment",
                                Student = new Student { Id = 55, StudentUniqueId = "22292332", Title = "Mr.", FirstName = "James", MiddleName = "Q", LastName = "Brown" },
                                School = "Eagle Point High",
                                Grade = "Eight",
                                ErrorCode = "16",
                                ErrorText = "Student address zip code not valid.",
                                Severity = aWarning
                            }};
                    break;
                default:
                    errorSummaryList = new List<ValidationErrorSummary>();
                    break;
            }

            return errorSummaryList;
        }
    }
}