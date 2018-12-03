﻿IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rules')
BEGIN
-- The schema must be run in its own batch!
EXEC( 'CREATE SCHEMA rules' );
END

GO 

IF OBJECT_ID('rules.StudentEnrollment','V') IS NOT NULL
	DROP VIEW rules.StudentEnrollment

GO

CREATE VIEW [rules].[StudentEnrollment]

AS

SELECT S.StudentUniqueId AS [id]
	 , S.StudentUniqueId AS [MARSSNumber]
	 , LEA.LocalEducationAgencyId AS [DistrictId]
	 , -1 AS [DistrictIdLeft]         
	 , -1 AS [DistrictIdRight]         
	 , SSA.SchoolId
	 , DT.CodeValue AS [DistrictType]
	 , RIGHT(CAST(LEA.LocalEducationAgencyId AS NVARCHAR(10)),4) AS [DistrictNumber]
	 , RIGHT(CAST(Sc.SchoolId AS NVARCHAR(10)),3) AS [SchoolNumber]
	 , SSA.EntryDate AS [StatusBeginDate]
	 , ROW_NUMBER ()
			OVER(PARTITION BY S.StudentUniqueId ORDER BY SSA.EntryDate, SSA.SchoolId) AS [EnrollmentSequence]
	 , DET.CodeValue AS [LastLocationOfAttendance]
	 , SSA.ExitWithdrawDate AS [StatusEndDate]
	 , DEWT.CodeValue AS [StatusEnd]
	 , DGL.CodeValue AS [StudentGradeLevel]
	 , DSFSE.CodeValue AS [EconomicIndicatorCode]
	 , SSAE.HomeboundServiceIndicator
	 , HSF.HomelessStudentFlag
	 , M.COEMigrantIndicator
	 , ISI.IndependentStudyIndicator
	 , SE.Section504Placement
	 , SE.Section504PlacementBeginDate
	 , SE.Section504PlacementEndDate
	 , TII.Title1Indicator
	 , DSEES.CodeValue AS [SpecialEducationEvaluationStatus]
	 , E.EnglishLearnerStartDate
	 , RIGHT(CAST(RLEA.LocalEducationAgencyId AS NVARCHAR(10)),4) AS [StudentResidentDistrictNumber]
	 , RDT.CodeValue AS [StudentResidentDistrictType]
	 , DS.CodeValue AS [SchoolClassification]
FROM edfi.Student S
JOIN edfi.StudentSchoolAssociation SSA ON SSA.StudentUSI = S.StudentUSI
JOIN extension.StudentSchoolAssociationExtension SSAE ON SSAE.StudentUSI = SSA.StudentUSI
	AND SSAE.SchoolId = SSA.SchoolId
	AND SSAE.EntryDate = SSA.EntryDate
LEFT JOIN edfi.EntryTypeDescriptor ETD ON ETD.EntryTypeDescriptorId = SSA.EntryTypeDescriptorId
LEFT JOIN edfi.Descriptor DET ON DET.DescriptorId = ETD.EntryTypeDescriptorId
	AND DET.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN edfi.ExitWithdrawTypeDescriptor EWTD ON EWTD.ExitWithdrawTypeDescriptorId = SSA.ExitWithdrawTypeDescriptorId
LEFT JOIN edfi.Descriptor DEWT ON DEWT.DescriptorId = EWTD.ExitWithdrawTypeDescriptorId
	AND DEWT.Namespace LIKE 'http://education.mn.gov%'
JOIN edfi.GradeLevelDescriptor GLD ON GLD.GradeLevelDescriptorId = SSA.EntryGradeLevelDescriptorId
JOIN edfi.Descriptor DGL ON DGL.DescriptorId = GLD.GradeLevelDescriptorId
	AND DGL.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN edfi.SchoolFoodServicesEligibilityDescriptor SFSED ON SFSED.SchoolFoodServicesEligibilityDescriptorId = SSAE.SchoolFoodServicesEligibilityDescriptorId
LEFT JOIN edfi.Descriptor DSFSE ON DSFSE.DescriptorId = SFSED.SchoolFoodServicesEligibilityDescriptorId
	AND DSFSE.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN 
	(SELECT SEOA.StudentUSI
		  , SEOA.EducationOrganizationId
		  , 1 AS [HomelessStudentFlag]
	 FROM edfi.StudentEducationOrganizationAssociation SEOA
	 JOIN extension.StudentEducationOrganizationAssociationExtension SEOAE ON SEOAE.StudentUSI = SEOA.StudentUSI
		AND SEOAE.EducationOrganizationId = SEOA.EducationOrganizationId
		AND SEOAE.ResponsibilityDescriptorId = SEOA.ResponsibilityDescriptorId
	 JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic SEOASC ON SEOASC.StudentUSI = SEOAE.StudentUSI
		AND SEOASC.EducationOrganizationId = SEOAE.EducationOrganizationId
		AND SEOASC.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
	 JOIN edfi.StudentCharacteristicDescriptor SCD ON SCD.StudentCharacteristicDescriptorId = SEOASC.StudentCharacteristicDescriptorId
	 JOIN edfi.Descriptor DSC ON DSC.DescriptorId = SCD.StudentCharacteristicDescriptorId
		AND DSC.CodeValue = 'Homeless'
		AND DSC.Namespace LIKE 'http://education.mn.gov%'
	 JOIN edfi.ResponsibilityDescriptor RD ON RD.ResponsibilityDescriptorId = SEOA.ResponsibilityDescriptorId
	 JOIN edfi.Descriptor DR ON DR.DescriptorId = RD.ResponsibilityDescriptorId
		AND DR.CodeValue = 'Demographic'
		AND DR.Namespace LIKE 'http://education.mn.gov%'
	 ) HSF ON HSF.StudentUSI = SSA.StudentUSI
		   AND HSF.EducationOrganizationId = SSA.SchoolId
LEFT JOIN (
	SELECT SEOA.StudentUSI
		 , SEOA.EducationOrganizationId
		 , 1 AS [COEMigrantIndicator]
	FROM edfi.StudentEducationOrganizationAssociation SEOA
	 JOIN extension.StudentEducationOrganizationAssociationExtension SEOAE ON SEOAE.StudentUSI = SEOA.StudentUSI
		AND SEOAE.EducationOrganizationId = SEOA.EducationOrganizationId
		AND SEOAE.ResponsibilityDescriptorId = SEOA.ResponsibilityDescriptorId
	 JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic SEOASC ON SEOASC.StudentUSI = SEOAE.StudentUSI
		AND SEOASC.EducationOrganizationId = SEOAE.EducationOrganizationId
		AND SEOASC.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
	JOIN edfi.StudentCharacteristicDescriptor SCD ON SCD.StudentCharacteristicDescriptorId = SEOASC.StudentCharacteristicDescriptorId
	JOIN edfi.Descriptor DSC ON DSC.DescriptorId = SCD.StudentCharacteristicDescriptorId
		AND DSC.CodeValue = 'Migrant'
		AND DSC.Namespace LIKE 'http://education.mn.gov%'
	JOIN edfi.ResponsibilityDescriptor RD ON RD.ResponsibilityDescriptorId = SEOA.ResponsibilityDescriptorId
	JOIN edfi.Descriptor DR ON DR.DescriptorId = RD.ResponsibilityDescriptorId
		AND DR.CodeValue = 'Demographic'
		AND DR.Namespace LIKE 'http://education.mn.gov%'
	) M ON M.StudentUSI = SSA.StudentUSI
		  AND M.EducationOrganizationId = SSA.SchoolId
LEFT JOIN 
	(SELECT SSASPP.StudentUSI
		  , SSASPP.SchoolId
		  , SSASPP.EntryDate
		  , 1 AS [IndependentStudyIndicator]
	 FROM extension.StudentSchoolAssociationStudentProgramParticipation SSASPP
	 JOIN extension.ProgramCategoryDescriptor PCD ON PCD.ProgramCategoryDescriptorId = SSASPP.ProgramCategoryDescriptorId
	 JOIN edfi.Descriptor DPC ON DPC.DescriptorId = PCD.ProgramCategoryDescriptorId
		AND DPC.CodeValue = 'Independent Study'
		AND DPC.Namespace LIKE 'http://education.mn.gov%'
	 ) ISI ON ISI.StudentUSI = SSAE.StudentUSI
		   AND ISI.SchoolId = SSAE.SchoolId
		   AND ISI.EntryDate = SSAE.EntryDate
LEFT JOIN 
	(SELECT SSASPP.StudentUSI
		  , SSASPP.SchoolId
		  , SSASPP.EntryDate
		  , 1 AS [Section504Placement]
		  , SSASPP.BeginDate AS [Section504PlacementBeginDate]
		  , SSASPP.EndDate AS [Section504PlacementEndDate]
	 FROM extension.StudentSchoolAssociationStudentProgramParticipation SSASPP
	 JOIN extension.ProgramCategoryDescriptor PCD ON PCD.ProgramCategoryDescriptorId = SSASPP.ProgramCategoryDescriptorId
	 JOIN edfi.Descriptor DPC ON DPC.DescriptorId = PCD.ProgramCategoryDescriptorId
		AND DPC.CodeValue = 'Section 504 Placement'
		AND DPC.Namespace LIKE 'http://education.mn.gov%'
	 ) SE ON SE.StudentUSI = SSAE.StudentUSI
		  AND SE.SchoolId = SSAE.SchoolId
		  AND SE.EntryDate = SSAE.EntryDate
LEFT JOIN 
	(SELECT SSASPP.StudentUSI
		  , SSASPP.SchoolId
		  , SSASPP.EntryDate
		  , 1 AS [Title1Indicator]
	 FROM extension.StudentSchoolAssociationStudentProgramParticipation SSASPP
	 JOIN extension.ProgramCategoryDescriptor PCD ON PCD.ProgramCategoryDescriptorId = SSASPP.ProgramCategoryDescriptorId
	 JOIN edfi.Descriptor DPC ON DPC.DescriptorId = PCD.ProgramCategoryDescriptorId
		AND DPC.CodeValue = 'Title I Part A'
		AND DPC.Namespace LIKE 'http://education.mn.gov%'
	 ) TII ON TII.StudentUSI = SSAE.StudentUSI
		  AND TII.SchoolId = SSAE.SchoolId
		  AND TII.EntryDate = SSAE.EntryDate
LEFT JOIN extension.SpecialEducationEvaluationStatusDescriptor SEESD 
	ON SEESD.SpecialEducationEvaluationStatusDescriptorId = SSAE.SpecialEducationEvaluationStatusDescriptorId
LEFT JOIN edfi.Descriptor DSEES ON DSEES.DescriptorId = SEESD.SpecialEducationEvaluationStatusDescriptorId
	AND DSEES.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN (
	SELECT SSASPP.StudentUSI
		 , SSASPP.SchoolId
		 , SSASPP.EntryDate
		 , SSASPP.BeginDate AS [EnglishLearnerStartDate]
	FROM extension.StudentSchoolAssociationStudentProgramParticipation SSASPP
	JOIN extension.ProgramCategoryDescriptor PCD ON PCD.ProgramCategoryDescriptorId = SSASPP.ProgramCategoryDescriptorId
	JOIN edfi.Descriptor DPC ON DPC.DescriptorId = PCD.ProgramCategoryDescriptorId
		AND DPC.CodeValue = 'English Learner Served'
		AND DPC.Namespace LIKE 'http://education.mn.gov%'
	) E ON E.StudentUSI = SSAE.StudentUSI
		  AND E.SchoolId = SSAE.SchoolId
		  AND E.EntryDate = SSAE.EntryDate
LEFT JOIN edfi.LocalEducationAgency RLEA ON RLEA.LocalEducationAgencyId = SSAE.ResidentLocalEducationAgencyId
LEFT JOIN edfi.DistrictTypeDescriptor RDTD ON RDTD.DistrictTypeDescriptorId = RLEA.DistrictTypeDescriptorId
LEFT JOIN edfi.Descriptor RDT ON RDT.DescriptorId = RDTD.DistrictTypeDescriptorId
	AND RDT.Namespace LIKE 'http://education.mn.gov%'
JOIN edfi.School Sc ON Sc.SchoolId = SSA.SchoolId
LEFT JOIN edfi.SchoolClassificationDescriptor SD ON SD.SchoolClassificationDescriptorId = Sc.SchoolClassificationDescriptorId
LEFT JOIN edfi.Descriptor DS ON DS.DescriptorId = SD.SchoolClassificationDescriptorId
	AND DS.Namespace LIKE 'http://education.mn.gov%'
JOIN edfi.LocalEducationAgency LEA ON LEA.LocalEducationAgencyId = Sc.LocalEducationAgencyId
LEFT JOIN edfi.DistrictTypeDescriptor DTD ON DTD.DistrictTypeDescriptorId = LEA.DistrictTypeDescriptorId
LEFT JOIN edfi.Descriptor DT ON DT.DescriptorId = DTD.DistrictTypeDescriptorId
	AND DT.Namespace LIKE 'http://education.mn.gov%';



GO

IF OBJECT_ID('rules.StudentDemographic','V') IS NOT NULL
	DROP VIEW rules.StudentDemographic

GO

CREATE VIEW [rules].[StudentDemographic] 
AS

SELECT S.StudentUniqueId AS [id]
	 , S.StudentUniqueId AS [MARSSNumber]
	 , LEA.LocalEducationAgencyId AS [DistrictId]
	 , -1 AS [DistrictIdLeft]         
	 , -1 AS [DistrictIdRight]         
	 , SEOA.EducationOrganizationId AS [SchoolId]
	 , LTRIM(RTRIM(SEOAE.FirstName)) AS [FirstName]
	 , LTRIM(RTRIM(SEOAE.MiddleName)) AS [MiddleName]
	 , LTRIM(RTRIM(SEOAE.LastSurname)) AS [LastName]
	 , SEOAE.GenerationCodeSuffix AS [Suffix]
	 , SEOAE.BirthDate
	 , ST.ShortDescription AS [Gender]
	 , SEOAE.HispanicLatinoEthnicity AS [HispanicIndicator]
	 , AI.AsianIndicator
	 , BI.BlackIndicator
	 , II.IndianIndicator
	 , PII.PacificIslanderIndicator
	 , WI.WhiteIndicator
	 , EC.EthnicCode
	 , DAEO.CodeValue AS [AncestryEthnicOrigin]
	 , HPL.HomePrimaryLanguage
	 , DLEP.CodeValue AS [EnglishLearner]
	 , LUD.LocalUseData
FROM edfi.StudentEducationOrganizationAssociation SEOA
JOIN extension.StudentEducationOrganizationAssociationExtension SEOAE
	ON SEOAE.StudentUSI = SEOA.StudentUSI
	AND SEOAE.ResponsibilityDescriptorId = SEOA.ResponsibilityDescriptorId
	AND SEOAE.EducationOrganizationId = SEOA.EducationOrganizationId
JOIN edfi.Student S ON S.StudentUSI = SEOA.StudentUSI
JOIN edfi.ResponsibilityDescriptor RD ON RD.ResponsibilityDescriptorId = SEOA.ResponsibilityDescriptorId
JOIN edfi.Descriptor DR ON DR.DescriptorId = RD.ResponsibilityDescriptorId
	AND DR.CodeValue = 'Demographic'
	AND DR.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN edfi.SexType ST ON ST.SexTypeId = SEOAE.SexTypeId
LEFT JOIN (
	SELECT SEOAR.StudentUSI
		 , SEOAR.ResponsibilityDescriptorId
		 , SEOAR.EducationOrganizationId
		 , 1 AS [AsianIndicator]
	FROM extension.StudentEducationOrganizationAssociationRace SEOAR
	JOIN edfi.RaceType RT ON RT.RaceTypeId = SEOAR.RaceTypeId
		 AND RT.ShortDescription = 'Asian'
	) AI ON AI.StudentUSI = SEOAE.StudentUSI
		 AND AI.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
		 AND AI.EducationOrganizationId = SEOAE.EducationOrganizationId
LEFT JOIN (
	SELECT SEOAR.StudentUSI
		 , SEOAR.ResponsibilityDescriptorId
		 , SEOAR.EducationOrganizationId
		 , 1 AS [BlackIndicator]
	FROM extension.StudentEducationOrganizationAssociationRace SEOAR
	JOIN edfi.RaceType RT ON RT.RaceTypeId = SEOAR.RaceTypeId
		 AND RT.ShortDescription = 'Black - African American'
	) BI ON BI.StudentUSI = SEOAE.StudentUSI
		 AND BI.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
		 AND BI.EducationOrganizationId = SEOAE.EducationOrganizationId
LEFT JOIN (
	SELECT SEOAR.StudentUSI
		 , SEOAR.ResponsibilityDescriptorId
		 , SEOAR.EducationOrganizationId
		 , 1 AS [IndianIndicator]
	FROM extension.StudentEducationOrganizationAssociationRace SEOAR
	JOIN edfi.RaceType RT ON RT.RaceTypeId = SEOAR.RaceTypeId
		 AND RT.ShortDescription = 'American Indian - Alaskan Native'
	) II ON II.StudentUSI = SEOAE.StudentUSI
		 AND II.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
		 AND II.EducationOrganizationId = SEOAE.EducationOrganizationId
LEFT JOIN (
	SELECT SEOAR.StudentUSI
		 , SEOAR.ResponsibilityDescriptorId
		 , SEOAR.EducationOrganizationId
		 , 1 AS [PacificIslanderIndicator]
	FROM extension.StudentEducationOrganizationAssociationRace SEOAR
	JOIN edfi.RaceType RT ON RT.RaceTypeId = SEOAR.RaceTypeId
		 AND RT.ShortDescription = 'Native Hawaiian - Pacific Islander'
	) PII ON PII.StudentUSI = SEOAE.StudentUSI
		 AND PII.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
		 AND PII.EducationOrganizationId = SEOAE.EducationOrganizationId
LEFT JOIN (
	SELECT SEOAR.StudentUSI
		 , SEOAR.ResponsibilityDescriptorId
		 , SEOAR.EducationOrganizationId
		 , 1 AS [WhiteIndicator]
	FROM extension.StudentEducationOrganizationAssociationRace SEOAR
	JOIN edfi.RaceType RT ON RT.RaceTypeId = SEOAR.RaceTypeId
		 AND RT.ShortDescription = 'White'
	) WI ON WI.StudentUSI = SEOAE.StudentUSI
		 AND WI.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
		 AND WI.EducationOrganizationId = SEOAE.EducationOrganizationId
LEFT JOIN (
	SELECT SEOASC.StudentUSI
		 , SEOASC.ResponsibilityDescriptorId
		 , SEOASC.EducationOrganizationId
		 , DSC.CodeValue AS [EthnicCode]
	FROM extension.StudentEducationOrganizationAssociationStudentCharacteristic SEOASC
	JOIN edfi.StudentCharacteristicDescriptor SCD ON SCD.StudentCharacteristicDescriptorId = SEOASC.StudentCharacteristicDescriptorId
	JOIN edfi.Descriptor DSC ON DSC.DescriptorId = SCD.StudentCharacteristicDescriptorId
			AND DSC.CodeValue = 'American Indian - Alaskan Native (Minnesota)'
			AND DSC.Namespace LIKE 'http://education.mn.gov%'
	) EC ON EC.StudentUSI = SEOAE.StudentUSI
		 AND EC.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
		 AND EC.EducationOrganizationId = SEOAE.EducationOrganizationId
LEFT JOIN extension.StudentEducationOrganizationAssociationAncestryEthnicOrigin SEOAAEO
	ON SEOAAEO.StudentUSI = SEOAE.StudentUSI
	AND SEOAAEO.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
	AND SEOAAEO.EducationOrganizationId = SEOAE.EducationOrganizationId
LEFT JOIN extension.AncestryEthnicOriginDescriptor AEOD ON AEOD.AncestryEthnicOriginDescriptorId = SEOAAEO.AncestryEthnicOriginDescriptorId
LEFT JOIN edfi.Descriptor DAEO ON DAEO.DescriptorId = AEOD.AncestryEthnicOriginDescriptorId
	AND DAEO.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN (
	SELECT SEOAL.StudentUSI
		 , SEOAL.EducationOrganizationId
		 , SEOAL.ResponsibilityDescriptorId
		 , DL.CodeValue AS [HomePrimaryLanguage]
	FROM extension.StudentEducationOrganizationAssociationLanguage SEOAL
	JOIN edfi.LanguageDescriptor LD ON LD.LanguageDescriptorId = SEOAL.LanguageDescriptorId
	JOIN edfi.Descriptor DL ON DL.DescriptorId = SEOAL.LanguageDescriptorId
		AND DL.Namespace LIKE 'http://education.mn.gov%'
	JOIN extension.StudentEducationOrganizationAssociationLanguageUse SEOALU 
		ON SEOALU.EducationOrganizationId = SEOAL.EducationOrganizationId
		AND SEOALU.StudentUSI = SEOAL.StudentUSI
		AND SEOALU.ResponsibilityDescriptorId = SEOAL.ResponsibilityDescriptorId
		AND SEOALU.LanguageDescriptorId = SEOAL.LanguageDescriptorId
	JOIN edfi.LanguageUseType LUT ON LUT.LanguageUseTypeId = SEOALU.LanguageUseTypeId
		AND LUT.ShortDescription = 'Home language'
	) HPL ON HPL.StudentUSI = SEOAE.StudentUSI
	AND HPL.EducationOrganizationId = SEOAE.EducationOrganizationId
	AND HPL.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
LEFT JOIN edfi.LimitedEnglishProficiencyDescriptor LEPD ON LEPD.LimitedEnglishProficiencyDescriptorId = SEOAE.LimitedEnglishProficiencyDescriptorId
LEFT JOIN edfi.Descriptor DLEP ON DLEP.DescriptorId = LEPD.LimitedEnglishProficiencyDescriptorId
	AND DLEP.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN (
	SELECT IC.StudentUSI
		 , IC.EducationOrganizationId
		 , IC.ResponsibilityDescriptorId
		 , IC.IdentificationCode AS [LocalUseData]
	FROM extension.StudentEducationOrganizationAssociationStudentIdentificationCode IC
	JOIN edfi.StudentIdentificationSystemDescriptor SISD ON SISD.StudentIdentificationSystemDescriptorId = IC.StudentIdentificationSystemDescriptorId
	JOIN edfi.Descriptor DSIS ON DSIS.DescriptorId = SISD.StudentIdentificationSystemDescriptorId
		AND DSIS.CodeValue = 'Local'
		AND DSIS.Namespace LIKE 'http://education.mn.gov%'
	) LUD ON LUD.StudentUSI = SEOAE.StudentUSI
		  AND LUD.EducationOrganizationId = SEOAE.EducationOrganizationId
		  AND LUD.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
JOIN edfi.School Sc ON Sc.SchoolId = SEOA.EducationOrganizationId
JOIN edfi.LocalEducationAgency LEA ON LEA.LocalEducationAgencyId = Sc.LocalEducationAgencyId;
GO

IF OBJECT_ID('rules.SSDC','V') IS NOT NULL
	DROP VIEW rules.SSDC

GO


CREATE VIEW [rules].[SSDC]

AS

SELECT S.StudentUniqueId AS [id]
	 , S.StudentUniqueId AS [MARSSNumber]
	 , LEA.LocalEducationAgencyId AS [DistrictId]
	 , -1 AS [DistrictIdLeft]         
	 , -1 AS [DistrictIdRight]         
	 , SEOA.EducationOrganizationId AS [SchoolId]
	 , ADP.ActiveDutyParentIndicator
	 , II.ImmigrantIndicator
	 , RAEL.RecentlyArrivedEnglishLearner
	 , SLIFE.SLIFE
FROM edfi.Student S
JOIN edfi.StudentEducationOrganizationAssociation SEOA ON SEOA.StudentUSI = S.StudentUSI
JOIN extension.StudentEducationOrganizationAssociationExtension SEOAE ON SEOAE.StudentUSI = SEOA.StudentUSI
	AND SEOAE.EducationOrganizationId = SEOA.EducationOrganizationId
	AND SEOAE.ResponsibilityDescriptorId = SEOA.ResponsibilityDescriptorId
JOIN edfi.School Sc ON Sc.SchoolId = SEOA.EducationOrganizationId
JOIN edfi.LocalEducationAgency LEA ON LEA.LocalEducationAgencyId = Sc.LocalEducationAgencyId
LEFT JOIN (
	SELECT SEOASC.StudentUSI
		 , SEOASC.EducationOrganizationId
		 , SEOASC.ResponsibilityDescriptorId
		 , 1 AS [ActiveDutyParentIndicator]
	FROM extension.StudentEducationOrganizationAssociationStudentCharacteristic SEOASC
	JOIN edfi.StudentCharacteristicDescriptor SCD ON SCD.StudentCharacteristicDescriptorId = SEOASC.StudentCharacteristicDescriptorId
	JOIN edfi.Descriptor DSC ON DSC.DescriptorId = SCD.StudentCharacteristicDescriptorId
		AND DSC.CodeValue = 'Active Duty Parent (ADP)'
		AND DSC.Namespace LIKE 'http://education.mn.gov%'
	) ADP ON ADP.StudentUSI = SEOAE.StudentUSI
		  AND ADP.EducationOrganizationId = SEOAE.EducationOrganizationId
		  AND ADP.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
LEFT JOIN (
	SELECT SEOASC.StudentUSI
		 , SEOASC.EducationOrganizationId
		 , SEOASC.ResponsibilityDescriptorId
		 , 1 AS [ImmigrantIndicator]
	FROM extension.StudentEducationOrganizationAssociationStudentCharacteristic SEOASC
	JOIN edfi.StudentCharacteristicDescriptor SCD ON SCD.StudentCharacteristicDescriptorId = SEOASC.StudentCharacteristicDescriptorId
	JOIN edfi.Descriptor DSC ON DSC.DescriptorId = SCD.StudentCharacteristicDescriptorId
		AND DSC.CodeValue = 'Immigrant'
		AND DSC.Namespace LIKE 'http://education.mn.gov%'
	) II ON II.StudentUSI = SEOAE.StudentUSI
		  AND II.EducationOrganizationId = SEOAE.EducationOrganizationId
		  AND II.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
LEFT JOIN (
	SELECT SEOASC.StudentUSI
		 , SEOASC.EducationOrganizationId
		 , SEOASC.ResponsibilityDescriptorId
		 , 1 AS [RecentlyArrivedEnglishLearner]
	FROM extension.StudentEducationOrganizationAssociationStudentCharacteristic SEOASC
	JOIN edfi.StudentCharacteristicDescriptor SCD ON SCD.StudentCharacteristicDescriptorId = SEOASC.StudentCharacteristicDescriptorId
	JOIN edfi.Descriptor DSC ON DSC.DescriptorId = SCD.StudentCharacteristicDescriptorId
		AND DSC.CodeValue = 'Recently Arrived English Learner (RAEL)'
		AND DSC.Namespace LIKE 'http://education.mn.gov%'
	) RAEL ON RAEL.StudentUSI = SEOAE.StudentUSI
		  AND RAEL.EducationOrganizationId = SEOAE.EducationOrganizationId
		  AND RAEL.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId
LEFT JOIN (
	SELECT SEOASC.StudentUSI
		 , SEOASC.EducationOrganizationId
		 , SEOASC.ResponsibilityDescriptorId
		 , 1 AS [SLIFE]
	FROM extension.StudentEducationOrganizationAssociationStudentCharacteristic SEOASC
	JOIN edfi.StudentCharacteristicDescriptor SCD ON SCD.StudentCharacteristicDescriptorId = SEOASC.StudentCharacteristicDescriptorId
	JOIN edfi.Descriptor DSC ON DSC.DescriptorId = SCD.StudentCharacteristicDescriptorId
		AND DSC.CodeValue = 'SLIFE'
		AND DSC.Namespace LIKE 'http://education.mn.gov%'
	) SLIFE ON SLIFE.StudentUSI = SEOAE.StudentUSI
		  AND SLIFE.EducationOrganizationId = SEOAE.EducationOrganizationId
		  AND SLIFE.ResponsibilityDescriptorId = SEOAE.ResponsibilityDescriptorId;
GO

IF OBJECT_ID('rules.MultipleEnrollment','V') IS NOT NULL
	DROP VIEW rules.MultipleEnrollment

GO

CREATE VIEW [rules].[MultipleEnrollment] 
AS

SELECT S.StudentUniqueId AS [id]
	 , S.StudentUniqueId AS [MARSSNumber]
	 , SSA1.EnrollmentSequence AS [EnrollmentSequenceLeft]
	 , -1 AS [DistrictId]         
	 , LEA1.LocalEducationAgencyId AS [DistrictIdLeft]
	 , SSA1.SchoolId AS [SchoolIdLeft]
	 , DSC1.CodeValue AS [SchoolClassificationLeft]
	 , SSAE1.ResidentLocalEducationAgencyId AS [ResidentDistrictLeft]
	 , SSA1.EntryDate AS [StatusBeginDateLeft]
	 , SSA1.ExitWithdrawDate AS [StatusEndDateLeft]
	 , DET1.CodeValue AS [LastLocationOfAttendanceLeft]
	 , DGL1.CodeValue AS [StudentGradeLevelLeft]
	 , DSEES1.CodeValue AS [SpecialEducationEvaluationStatusLeft]
	 , SSA2.EnrollmentSequence AS [EnrollmentSequenceRight]
	 , LEA2.LocalEducationAgencyId AS [DistrictIdRight]
	 , SSA2.SchoolId AS [SchoolIdRight]
	 , DSC2.CodeValue AS [SchoolClassificationRight]
	 , SSAE2.ResidentLocalEducationAgencyId AS [ResidentDistrictRight]
	 , SSA2.EntryDate AS [StatusBeginDateRight]
	 , SSA2.ExitWithdrawDate AS [StatusEndDateRight]
	 , DET2.CodeValue AS [LastLocationOfAttendanceRight]
	 , DGL2.CodeValue AS [StudentGradeLevelRight]
	 , DSEES2.CodeValue AS [SpecialEducationEvaluationStatusRight]
	 , CASE 
		WHEN SSA2.EnrollmentOrder - SSA1.EnrollmentOrder = 1 THEN 1
		ELSE 0
	   END AS [IsNextEnrollment]
	 , CASE
		WHEN SSA1.ExitWithdrawDate IS NULL OR SSA2.EntryDate <= SSA1.ExitWithdrawDate THEN 1
		ELSE 0
	   END AS [EnrollmentOverlap]
	 , CASE
		WHEN (DSC1.CodeValue IN ('41','42','45') OR DSC2.CodeValue IN ('41','42','45'))
			AND (SSA1.ExitWithdrawDate IS NULL OR SSA2.EntryDate <= SSA1.ExitWithdrawDate)
		THEN 1
		ELSE 0
	   END AS [DualEnrolledIndicator]
	 , CASE
		WHEN DGL1.CodeValue = 'PS' 
			AND (CHARINDEX('K',DGL2.CodeValue)>0 
				OR DGL2.CodeValue = 'EC' 
				OR LEFT(DGL2.CodeValue,1) = 'R' 
				OR DGL2.CodeValue IN ('PA','PB','PC','PD','PE','PF','PG','PH','PI','PJ'))
			THEN 1
		WHEN DGL2.CodeValue = 'PS' 
			AND (CHARINDEX('K',DGL1.CodeValue)>0 
				OR DGL1.CodeValue = 'EC' 
				OR LEFT(DGL1.CodeValue,1) = 'R' 
				OR DGL1.CodeValue IN ('PA','PB','PC','PD','PE','PF','PG','PH','PI','PJ'))
			THEN 1
		WHEN DGL1.CodeValue IN ('PA','PB','PC','PD','PE','PF','PG','PH','PI','PJ')
			AND DGL2.CodeValue = 'EC'
			AND DSEES2.CodeValue = '2'
			THEN 1
		WHEN DGL2.CodeValue IN ('PA','PB','PC','PD','PE','PF','PG','PH','PI','PJ')
			AND DGL1.CodeValue = 'EC'
			AND DSEES1.CodeValue = '2'
			THEN 1
		WHEN LEFT(DGL1.CodeValue,1) = 'R'
			AND DGL2.CodeValue = 'EC'
			AND DSEES2.CodeValue = '2'
			THEN 1
		WHEN LEFT(DGL2.CodeValue,1) = 'R'
			AND DGL1.CodeValue = 'EC'
			AND DSEES1.CodeValue = '2'
			THEN 1
		ELSE 0
	   END AS [ValidSameSchoolOverlap]
FROM edfi.Student S
JOIN (
	SELECT StudentUSI
		 , SchoolId
		 , SchoolYear
		 , EntryDate
		 , EntryGradeLevelDescriptorId
		 , EntryTypeDescriptorId
		 , ExitWithdrawDate
		 , ExitWithdrawTypeDescriptorId
		 , ROW_NUMBER()
			OVER(PARTITION BY StudentUSI ORDER BY EntryDate,SchoolId) AS [EnrollmentSequence]
		 , DENSE_RANK()
			OVER(PARTITION BY StudentUSI ORDER BY EntryDate) AS [EnrollmentOrder]
	FROM edfi.StudentSchoolAssociation SSA 
	) SSA1 ON SSA1.StudentUSI = S.StudentUSI
JOIN edfi.School Sc1 ON Sc1.SchoolId = SSA1.SchoolId
JOIN edfi.LocalEducationAgency LEA1 ON LEA1.LocalEducationAgencyId = Sc1.LocalEducationAgencyId
LEFT JOIN edfi.SchoolClassificationDescriptor SCD1 ON SCD1.SchoolClassificationDescriptorId = Sc1.SchoolClassificationDescriptorId
LEFT JOIN edfi.Descriptor DSC1 ON DSC1.DescriptorId = SCD1.SchoolClassificationDescriptorId
	AND DSC1.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN edfi.EntryTypeDescriptor ETD1 ON ETD1.EntryTypeDescriptorId = SSA1.EntryTypeDescriptorId
LEFT JOIN edfi.Descriptor DET1 ON DET1.DescriptorId = ETD1.EntryTypeDescriptorId
	AND DET1.Namespace LIKE 'http://education.mn.gov%'
JOIN extension.StudentSchoolAssociationExtension SSAE1 ON SSAE1.StudentUSI = SSA1.StudentUSI
	AND SSAE1.SchoolId = SSA1.SchoolId
	AND SSAE1.EntryDate = SSA1.EntryDate
LEFT JOIN extension.SpecialEducationEvaluationStatusDescriptor SEESD1 
	ON SEESD1.SpecialEducationEvaluationStatusDescriptorId = SSAE1.SpecialEducationEvaluationStatusDescriptorId
LEFT JOIN edfi.Descriptor DSEES1 ON DSEES1.DescriptorId = SEESD1.SpecialEducationEvaluationStatusDescriptorId
	AND DSEES1.Namespace LIKE 'http://education.mn.gov%'
JOIN edfi.GradeLevelDescriptor GLD1 ON GLD1.GradeLevelDescriptorId = SSA1.EntryGradeLevelDescriptorId
JOIN edfi.Descriptor DGL1 ON DGL1.DescriptorId = GLD1.GradeLevelDescriptorId
	AND DGL1.Namespace LIKE 'http://education.mn.gov%'
JOIN (
	SELECT StudentUSI
		 , SchoolId
		 , SchoolYear
		 , EntryDate
		 , EntryGradeLevelDescriptorId
		 , EntryTypeDescriptorId
		 , ExitWithdrawDate
		 , ExitWithdrawTypeDescriptorId
		 , ROW_NUMBER()
			OVER(PARTITION BY StudentUSI ORDER BY EntryDate,SchoolId) AS [EnrollmentSequence]
		 , DENSE_RANK()
			OVER(PARTITION BY StudentUSI ORDER BY EntryDate) AS [EnrollmentOrder]
	FROM edfi.StudentSchoolAssociation SSA 
	) SSA2 ON SSA2.StudentUSI = S.StudentUSI
	AND SSA2.EnrollmentSequence > SSA1.EnrollmentSequence
JOIN edfi.School Sc2 ON Sc2.SchoolId = SSA1.SchoolId
JOIN edfi.LocalEducationAgency LEA2 ON LEA2.LocalEducationAgencyId = Sc2.LocalEducationAgencyId
LEFT JOIN edfi.SchoolClassificationDescriptor SCD2 ON SCD2.SchoolClassificationDescriptorId = Sc2.SchoolClassificationDescriptorId
LEFT JOIN edfi.Descriptor DSC2 ON DSC2.DescriptorId = SCD2.SchoolClassificationDescriptorId
	AND DSC2.Namespace LIKE 'http://education.mn.gov%'
LEFT JOIN edfi.EntryTypeDescriptor ETD2 ON ETD2.EntryTypeDescriptorId = SSA2.EntryTypeDescriptorId
LEFT JOIN edfi.Descriptor DET2 ON DET2.DescriptorId = ETD2.EntryTypeDescriptorId
	AND DET2.Namespace LIKE 'http://education.mn.gov%'
JOIN extension.StudentSchoolAssociationExtension SSAE2 ON SSAE2.StudentUSI = SSA2.StudentUSI
	AND SSAE2.SchoolId = SSA2.SchoolId
	AND SSAE2.EntryDate = SSA2.EntryDate
LEFT JOIN extension.SpecialEducationEvaluationStatusDescriptor SEESD2 
	ON SEESD2.SpecialEducationEvaluationStatusDescriptorId = SSAE2.SpecialEducationEvaluationStatusDescriptorId
LEFT JOIN edfi.Descriptor DSEES2 ON DSEES2.DescriptorId = SEESD2.SpecialEducationEvaluationStatusDescriptorId
	AND DSEES2.Namespace LIKE 'http://education.mn.gov%'
JOIN edfi.GradeLevelDescriptor GLD2 ON GLD2.GradeLevelDescriptorId = SSA2.EntryGradeLevelDescriptorId
JOIN edfi.Descriptor DGL2 ON DGL2.DescriptorId = GLD2.GradeLevelDescriptorId
	AND DGL2.Namespace LIKE 'http://education.mn.gov%';
GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ContainsDoubleSpace'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].[ContainsDoubleSpace]
GO

CREATE FUNCTION rules.ContainsDoubleSpace (@String VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @DoubleSpace AS BIT

SELECT @DoubleSpace = 
	   CASE
		WHEN CHARINDEX('  ',@String) > 0 THEN 1
		ELSE 0
	   END
RETURN @DoubleSpace;

END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ContainsInvalidChar'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].ContainsInvalidChar
GO

CREATE FUNCTION rules.ContainsInvalidChar
(
	@String AS VARCHAR(200)
)
RETURNS VARCHAR(200)
AS  
BEGIN

   IF LEN(LTRIM(RTRIM(@String)))>0
   BEGIN
	DECLARE @InvalidChar VARCHAR(200)	
	DECLARE @Index INT
	DECLARE @ASCIIChar INT

	SET @Index = 1
	SET @InvalidChar=0
	BEGIN     	 
      		WHILE @Index <= LEN(@String)
		BEGIN
    		SET @ASCIIChar=ASCII(SUBSTRING(@String, @Index, 1))
    		IF NOT @ASCIIChar BETWEEN 65 AND 90
		AND NOT @ASCIIChar BETWEEN 97 AND 122 
		AND NOT @ASCIIChar IN (32, 39, 45)
		SET @InvalidChar = 1
	        SET @Index = @Index + 1
    		END
	END    
   END
   ELSE
   BEGIN
	SET @InvalidChar = 0
   END

   RETURN (@InvalidChar)
END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ShortString'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].ShortString
GO

CREATE FUNCTION rules.ShortString (@String VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @ShortString AS BIT

SELECT @ShortString = 
	   CASE
		WHEN LEN(@String) < 2 THEN 1
		WHEN LEN(@String) = 2 AND (
			ASCII(SUBSTRING(@String,2,1)) NOT BETWEEN 65 AND 90 
		 OR ASCII(SUBSTRING(@String,2,1)) <> 39 
		 OR ASCII(SUBSTRING(@String,2,1)) NOT BETWEEN 97 AND 122
			) THEN 1
		ELSE 0 
	   END
RETURN @ShortString;

END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'StartsWithInvalidChar'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].StartsWithInvalidChar
GO

CREATE FUNCTION rules.StartsWithInvalidChar (@String VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @InvalidChar AS BIT

SELECT @InvalidChar = 
	   CASE
		WHEN @String IS NULL THEN 0
		WHEN (ASCII(LEFT(@String,1)) BETWEEN 65 and 90) THEN 0
		WHEN (ASCII(LEFT(@String,1)) BETWEEN 97 and 122) THEN 0
		ELSE 1
	   END
RETURN @InvalidChar;

END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ValidMARSSNumberFormat'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].ValidMARSSNumberFormat
GO

CREATE FUNCTION rules.ValidMARSSNumberFormat (@MARSSNumber VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @ValidMARSSNumber AS BIT

SELECT @ValidMARSSNumber = 
	   CASE
		WHEN @MARSSNumber LIKE '%[^0-9]%' THEN 0
		WHEN LEN(LTRIM(RTRIM(@MARSSNumber))) <> 13 THEN 0
		WHEN LEFT(@MARSSNumber,4) IN ('0000','5555') THEN 0
	   ELSE 1
	   END
RETURN @ValidMARSSNumber;

END;

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TYPES:  INT and NVARCHAR array types -----------------------------------------------------------
-- FUNCTION:  GET STUDENT DETAILS for Drilling down to Student-Level from Student Counts in other reports -----------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('rules.GetStudentEnrollmentDetails') IS NOT NULL   
    DROP FUNCTION rules.GetStudentEnrollmentDetails;  
GO

IF EXISTS(SELECT 1 FROM sys.types WHERE name = 'IdStringTable' AND is_table_type = 1 AND SCHEMA_ID('rules') = schema_id)
    DROP TYPE rules.IdStringTable;  

GO

IF EXISTS(SELECT 1 FROM sys.types WHERE name = 'IdIntTable' AND is_table_type = 1 AND SCHEMA_ID('rules') = schema_id)
    DROP TYPE rules.IdIntTable;  

GO

CREATE TYPE rules.IdIntTable AS TABLE (IdNumber INT);  

GO

CREATE TYPE rules.IdStringTable AS TABLE (IdNumber NVARCHAR(48));  

GO

-- Using the StudentUniqueID (NOT the StudentUSI)
CREATE FUNCTION rules.GetStudentEnrollmentDetails(@StudentIdList rules.IdStringTable READONLY)
	RETURNS TABLE
AS
RETURN
	SELECT 
		StudentId = st.StudentUniqueId,
        StudentFirstName = st.FirstName,
        StudentMiddleName = st.MiddleName,
        StudentLastName = st.LastSurname,
        DistrictName = distedorg.NameOfInstitution,
        DistrictId = distedorg.EducationOrganizationId,
        SchoolName = schedorg.NameOfInstitution,
        SchoolId = schedorg.EducationOrganizationId,
        EnrolledDate = ssa.EntryDate,
        WithdrawDate = ssa.ExitWithdrawDate,
		Grade = gradedesc.CodeValue,
		SpecialEdStatus = speddesc.ShortDescription
	FROM 
		edfi.student st
	INNER JOIN  @StudentIdList sil ON sil.IdNumber = st.StudentUniqueId
	INNER JOIN  edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = st.StudentUSI
	INNER JOIN  edfi.School sch ON sch.SchoolId = ssa.SchoolId
	LEFT OUTER JOIN edfi.EducationOrganization schedorg ON schedorg.EducationOrganizationId = sch.SchoolId
	LEFT OUTER JOIN edfi.EducationOrganization distedorg ON distedorg.EducationOrganizationId = sch.LocalEducationAgencyId
	LEFT OUTER JOIN edfi.Descriptor gradedesc ON gradedesc.DescriptorId = ssa.EntryGradeLevelDescriptorId
	LEFT OUTER JOIN extension.StudentSchoolAssociationExtension ssae ON ssae.StudentUSI = st.StudentUSI
	LEFT OUTER JOIN edfi.Descriptor speddesc ON speddesc.DescriptorId = ssae.SpecialEducationEvaluationStatusDescriptorId

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Race and Ancestral Ethnic Origin  ------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.RaceAEOReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.RaceAEOReport;  
GO  

CREATE PROCEDURE [rules].[RaceAEOReport]
	@distid int
AS

BEGIN
	DECLARE @RaceAEOTable TABLE (
		OrgType INT,  -- 100 = SCHOOL, 200 = DISTRICT, 300 = STATE
		EdOrgId INT,
		SchoolName nvarchar(255),
		DistrictEdOrgId int,
		DistrictName nvarchar(255),
		RaceGivenCount int,
		AncestryGivenCount int,
		DistinctEnrollmentCount int,
		DistinctDemographicsCount int
	);


	IF @distid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SCHOOL LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
		-- REGARDLESS of whether they have any enrollments or demographics.
		INSERT INTO @RaceAEOTable(
			OrgType, 
			EdOrgId, 
			SchoolName, 
			DistrictEdOrgId, 
			DistrictName, 
			DistinctEnrollmentCount, 
			DistinctDemographicsCount,
			RaceGivenCount,
			AncestryGivenCount)
			SELECT 
				100, -- SCHOOL LEVEL
				eorg.EducationOrganizationId AS EdOrgId,
				eorg.NameOfInstitution As SchoolName,
				eorgdist.EducationOrganizationId AS DistrictEdOrgId,
				eorgdist.NameOfInstitution AS DistrictName,
				DistinctEnrollmentCount = enr_distinct.quantity,
				DistinctDemographicsCount = dem_distinct.quantity,
				RaceGivenCount = rac_distinct.quantity,
				AncestryGivenCount = anc_distinct.quantity
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				-- To include duplicates (multiple records per student), use COUNT(1) instead
				OUTER APPLY (SELECT COUNT(DISTINCT ssa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
					WHERE ssa.SchoolId = eorg.EducationOrganizationId) enr_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId) dem_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoar.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationRace seoar ON seoar.StudentUSI = s.StudentUSI
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId) rac_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoaeo.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationAncestryEthnicOrigin seoaeo ON seoaeo.StudentUSI = s.StudentUSI
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId) anc_distinct
			WHERE @distid = eorgdist.EducationOrganizationId
			GROUP BY 
				eorg.EducationOrganizationId, 
				eorg.NameOfInstitution, 
				eorgdist.EducationOrganizationId, 
				eorgdist.NameOfInstitution,
				enr_distinct.quantity, 
				dem_distinct.quantity,
				rac_distinct.quantity,
				anc_distinct.quantity
		;
	END

	----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- DISTRICT LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
	-- REGARDLESS of whether they have any enrollments or demographics.
	INSERT INTO @RaceAEOTable(
		OrgType, 
		EdOrgId, 
		SchoolName,      -- Actually, the District name needed here.
		DistrictEdOrgId, -- NULL for District Level
		DistrictName,    -- NULL for District Level
		DistinctEnrollmentCount, 
		DistinctDemographicsCount,
		RaceGivenCount,
		AncestryGivenCount)
		SELECT 
			200, -- DISTRICT LEVEL
			eorgdist.EducationOrganizationId AS DistrictEdOrgId,
			eorgdist.NameOfInstitution AS DistrictName,
			NULL,
			NULL,
			DistinctEnrollmentCount = enr_distinct.quantity,
			DistinctDemographicsCount = dem_distinct.quantity,
			RaceGivenCount = rac_distinct.quantity,
			AncestryGivenCount = anc_distinct.quantity
		FROM 
			edfi.EducationOrganization eorgdist 
			INNER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = eorgdist.EducationOrganizationId
			-- To include duplicates (multiple records per student), use COUNT(1) instead
			OUTER APPLY (SELECT COUNT(DISTINCT ssa.StudentUSI) AS quantity 
				FROM edfi.Student s 
				INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
				INNER JOIN edfi.School sch ON ssa.SchoolId = sch.SchoolId
				WHERE sch.LocalEducationAgencyId = eorgdist.EducationOrganizationId) enr_distinct
			OUTER APPLY (SELECT COUNT(DISTINCT seoa.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON sch.SchoolId = seoa.EducationOrganizationId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId)) dem_distinct
			OUTER APPLY (SELECT COUNT(DISTINCT seoar.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationRace seoar ON seoar.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId)) rac_distinct
			OUTER APPLY (SELECT COUNT(DISTINCT seoaeo.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationAncestryEthnicOrigin seoaeo ON seoaeo.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId)) anc_distinct
		WHERE @distid = eorgdist.EducationOrganizationId OR @distid IS NULL
		GROUP BY 
			eorgdist.EducationOrganizationId, 
			eorgdist.NameOfInstitution,
			enr_distinct.quantity, 
			dem_distinct.quantity,
			rac_distinct.quantity,
			anc_distinct.quantity
	;

	IF @distid IS NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------

		-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
		-- REGARDLESS of whether they have any enrollments or demographics.
		INSERT INTO @RaceAEOTable(
			OrgType, 
			EdOrgId, 
			SchoolName,      -- Actually, the District name needed here.
			DistrictEdOrgId, -- NULL for District Level
			DistrictName,    -- NULL for District Level
			DistinctEnrollmentCount, 
			DistinctDemographicsCount,
			RaceGivenCount,
			AncestryGivenCount)
			SELECT 
				300, -- STATE LEVEL
				NULL AS DistrictEdOrgId,
				'State of Minnesota' AS SchoolName,
				NULL,
				NULL,
				DistinctEnrollmentCount = enr_distinct.quantity,
				DistinctDemographicsCount = dem_distinct.quantity,
				RaceGivenCount = rac_distinct.quantity,
				AncestryGivenCount = anc_distinct.quantity
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				-- To include duplicates (multiple records per student), use COUNT(1) instead
				OUTER APPLY (SELECT COUNT(DISTINCT ssa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI) enr_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI) dem_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoar.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationRace seoar ON seoar.StudentUSI = s.StudentUSI) rac_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoaeo.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationAncestryEthnicOrigin seoaeo ON seoaeo.StudentUSI = s.StudentUSI) anc_distinct
			GROUP BY 
				enr_distinct.quantity, 
				dem_distinct.quantity,
				rac_distinct.quantity,
				anc_distinct.quantity
		;
	END

	SELECT * FROM @RaceAEOTable ORDER BY OrgType DESC, SchoolName;
END

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Race and Ancestral Ethnic Origin StudentDetails ------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.RaceAEOStudentDetailsReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.RaceAEOStudentDetailsReport;  
GO  

CREATE PROCEDURE [rules].[RaceAEOStudentDetailsReport]
	@schoolid int,
	@distid int,
	@columnIndex int
AS

BEGIN
	DECLARE @StudentDetailsTable rules.IdStringTable;

	IF @schoolid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SCHOOL LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE sch.SchoolId = @schoolid
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
			WHERE sch.SchoolId = @schoolid
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
				INNER JOIN extension.StudentEducationOrganizationAssociationRace seoar ON seoar.StudentUSI = s.StudentUSI
			WHERE sch.SchoolId = @schoolid
			;
		END
		IF @columnIndex = 3
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
				INNER JOIN extension.StudentEducationOrganizationAssociationAncestryEthnicOrigin seoaeo ON seoaeo.StudentUSI = s.StudentUSI
			WHERE sch.SchoolId = @schoolid
		END
	END
	
	IF @distid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- DISTRICT LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT DISTINCT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
				WHERE @distid = eorgdist.EducationOrganizationId
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					INNER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
				WHERE @distid = eorgdist.EducationOrganizationId
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
					INNER JOIN extension.StudentEducationOrganizationAssociationRace seoar ON seoar.StudentUSI = s.StudentUSI
				WHERE @distid = eorgdist.EducationOrganizationId
			;
		END
		IF @columnIndex = 3
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
					INNER JOIN extension.StudentEducationOrganizationAssociationAncestryEthnicOrigin seoaeo ON seoaeo.StudentUSI = s.StudentUSI
				WHERE @distid = eorgdist.EducationOrganizationId
			;
		END
	END

	IF @distid IS NULL AND @schoolid IS NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT DISTINCT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					INNER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
					INNER JOIN extension.StudentEducationOrganizationAssociationRace seoar ON seoar.StudentUSI = s.StudentUSI
			;
		END
		IF @columnIndex = 3
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
				SELECT s.StudentUniqueId
				FROM 
					edfi.EducationOrganization eorgdist 
					LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
					LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
					INNER JOIN extension.StudentEducationOrganizationAssociationAncestryEthnicOrigin seoaeo ON seoaeo.StudentUSI = s.StudentUSI
			;
		END
		;
	END

	SELECT DISTINCT * FROM rules.GetStudentEnrollmentDetails(@StudentDetailsTable) enr ORDER BY enr.StudentId;
END

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Multiple Enrollments  ------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.MultipleEnrollmentReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.MultipleEnrollmentReport;  
GO  

CREATE PROCEDURE [rules].[MultipleEnrollmentReport]
	@distid int
AS

BEGIN
	DECLARE @MultipleEnrollmentsTable TABLE (
		OrgType INT,  -- 100 = SCHOOL, 200 = DISTRICT, 300 = STATE
		EdOrgId INT,
		SchoolName nvarchar(255),
		DistrictEdOrgId int,
		DistrictName nvarchar(255),
		TotalEnrollmentCount int,
		DistinctEnrollmentCount int,
		EnrolledInOtherSchoolsCount int,
		EnrolledInOtherDistrictsCount int
	);

	IF @distid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SCHOOL LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
		-- REGARDLESS of whether they have any multiple enrollments.
		INSERT INTO @MultipleEnrollmentsTable(
			OrgType, 
			EdOrgId, 
			SchoolName, 
			DistrictEdOrgId, 
			DistrictName,
			TotalEnrollmentCount, 
			DistinctEnrollmentCount
			)
			SELECT 
				100, -- SCHOOL LEVEL
				eorg.EducationOrganizationId AS EdOrgId,
				eorg.NameOfInstitution As SchoolName,
				eorgdist.EducationOrganizationId AS DistrictEdOrgId,
				eorgdist.NameOfInstitution AS DistrictName,
				enr.quantity_all AS TotalEnrollmentCount,
				enr.quantity AS DistinctEnrollmentCount
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				-- To include duplicates (multiple records per student), use COUNT(1) instead
				OUTER APPLY (SELECT COUNT(DISTINCT ssa.StudentUSI) AS quantity, COUNT(1) AS quantity_all 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
					WHERE ssa.SchoolId = eorg.EducationOrganizationId) enr
			WHERE @distid = eorgdist.EducationOrganizationId
			GROUP BY 
				eorg.EducationOrganizationId, 
				eorg.NameOfInstitution, 
				eorgdist.EducationOrganizationId, 
				eorgdist.NameOfInstitution,
				enr.quantity_all,
				enr.quantity
		;
		UPDATE @MultipleEnrollmentsTable
		SET EnrolledInOtherSchoolsCount = 
				(SELECT COUNT(DISTINCT s.StudentUSI) AS quantity 
				FROM edfi.School sch
				INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				INNER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
				WHERE DistrictEdOrgId = sch.LocalEducationAgencyId 
				GROUP BY s.StudentUSI
				HAVING COUNT(sch.SchoolId) > 1 AND EdOrgId IN (SELECT ssa3.SchoolId FROM edfi.StudentSchoolAssociation ssa3 WHERE s.StudentUSI = ssa3.StudentUSI)),
			EnrolledInOtherDistrictsCount = 
				(SELECT COUNT(DISTINCT st_in_sch.StudentUSI) 
				FROM
					(SELECT s.StudentUSI
					FROM edfi.School sch
					INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
					INNER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
					WHERE EdOrgId = sch.SchoolId) st_in_sch
				INNER JOIN edfi.StudentSchoolAssociation ssa2 ON ssa2.StudentUSI = st_in_sch.StudentUSI
				INNER JOIN edfi.School sch2 ON sch2.SchoolId = ssa2.SchoolId
				GROUP BY st_in_sch.StudentUSI
				HAVING COUNT(DISTINCT sch2.LocalEducationAgencyId) > 1)
			;
	END

	----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- DISTRICT LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
	-- REGARDLESS of whether they have any multiple enrollments.
	INSERT INTO @MultipleEnrollmentsTable(
		OrgType, 
		EdOrgId, 
		SchoolName, 
		DistrictEdOrgId, 
		DistrictName,
		TotalEnrollmentCount, 
		DistinctEnrollmentCount,
		EnrolledInOtherSchoolsCount,
		EnrolledInOtherDistrictsCount
		)
		SELECT 
			200, -- DISTRICT LEVEL
			eorgdist.EducationOrganizationId AS DistrictEdOrgId,
			eorgdist.NameOfInstitution As DistrictName,
			NULL AS Unused1,
			NULL AS Unused2,
			enr_distinct.quantity_all AS TotalEnrollmentCount,
			enr_distinct.quantity AS DistinctEnrollmentCount,
			enr_multiple.quantity AS EnrolledInOtherSchoolsCount,
			enr_multiple_district.quantity AS EnrolledInOtherDistrictsCount
		FROM 
			edfi.EducationOrganization eorgdist 
			-- ENSURE only districts and not schools by checking that the LEA table has an entry.
			INNER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = eorgdist.EducationOrganizationId
			OUTER APPLY (SELECT COUNT(1) AS quantity_all, COUNT(DISTINCT ssa.StudentUSI) AS quantity
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON ssa.SchoolId = sch.SchoolId
				WHERE sch.LocalEducationAgencyId = eorgdist.EducationOrganizationId) enr_distinct
			OUTER APPLY (SELECT COUNT(DISTINCT s.StudentUSI) AS quantity
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON ssa.SchoolId = sch.SchoolId
				WHERE sch.LocalEducationAgencyId = eorgdist.EducationOrganizationId
				GROUP BY s.StudentUSI
				HAVING COUNT(DISTINCT sch.SchoolId) > 1) enr_multiple
			OUTER APPLY (SELECT COUNT(DISTINCT st_in_sch.StudentUSI) as quantity
				FROM
					(SELECT s.StudentUSI
					FROM edfi.School sch
					INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
					INNER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
					WHERE eorgdist.EducationOrganizationId = sch.LocalEducationAgencyId) st_in_sch
				INNER JOIN edfi.StudentSchoolAssociation ssa2 ON ssa2.StudentUSI = st_in_sch.StudentUSI
				INNER JOIN edfi.School sch2 ON sch2.SchoolId = ssa2.SchoolId
				GROUP BY st_in_sch.StudentUSI
				HAVING COUNT(DISTINCT sch2.LocalEducationAgencyId) > 1) enr_multiple_district
		WHERE @distid = eorgdist.EducationOrganizationId OR @distid IS NULL
		GROUP BY 
			eorgdist.EducationOrganizationId, 
			eorgdist.NameOfInstitution, 
			enr_distinct.quantity_all,
			enr_distinct.quantity,
			enr_multiple.quantity,
			enr_multiple_district.quantity
	;

	IF @distid IS NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------

		INSERT INTO @MultipleEnrollmentsTable(
			OrgType, 
			EdOrgId, 
			SchoolName, 
			DistrictEdOrgId, 
			DistrictName,
			TotalEnrollmentCount, 
			DistinctEnrollmentCount,
			EnrolledInOtherSchoolsCount,
			EnrolledInOtherDistrictsCount
			)
			SELECT 
				300, -- STATE LEVEL
				NULL AS DistrictEdOrgId,
				'State of Minnesota' AS SchoolName,
				NULL,
				NULL,
				TotalEnrollmentCount = enr.quantity_all,
				DistinctEnrollmentCount = enr.quantity,
				EnrolledInOtherSchoolsCount = enr_multiple_school.quantity,
				EnrolledInOtherDistrictssCount = enr_multiple_district.quantity
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				-- To include duplicates (multiple records per student), use COUNT(1) instead
				OUTER APPLY (SELECT COUNT(1) AS quantity_all, COUNT(DISTINCT s.StudentUSI) AS quantity
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI) enr
				OUTER APPLY (SELECT COUNT(DISTINCT s.StudentUSI) AS quantity 
					FROM edfi.Student s 
					INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
					INNER JOIN edfi.School sch ON ssa.SchoolId = sch.SchoolId
					GROUP BY s.StudentUSI, sch.LocalEducationAgencyId
					HAVING COUNT(*) > 1) enr_multiple_school
				OUTER APPLY (SELECT COUNT(DISTINCT s.StudentUSI) AS quantity 
					FROM edfi.Student s 
					INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
					INNER JOIN edfi.School sch ON ssa.SchoolId = sch.SchoolId
					GROUP BY s.StudentUSI
					HAVING COUNT(DISTINCT sch.LocalEducationAgencyId) > 1) enr_multiple_district
			GROUP BY 
				enr.quantity_all,
				enr.quantity,
				enr_multiple_school.quantity,
				enr_multiple_district.quantity
		;
	END

	SELECT OrgType, 
		EdOrgId, 
		SchoolName, 
		DistrictEdOrgId, 
		DistrictName,
		TotalEnrollmentCount, 
		DistinctEnrollmentCount,
		COALESCE(EnrolledInOtherSchoolsCount,0) AS EnrolledInOtherSchoolsCount,
		COALESCE(EnrolledInOtherDistrictsCount,0) AS EnrolledInOtherDistrictsCount
	FROM @MultipleEnrollmentsTable 
	ORDER BY OrgType DESC, SchoolName;
END

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Multiple Enrollments StudentDetails --------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.MultipleEnrollmentStudentDetailsReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.MultipleEnrollmentStudentDetailsReport;  
GO  

CREATE PROCEDURE [rules].[MultipleEnrollmentStudentDetailsReport]
	@schoolid int,
	@distid int,
	@columnIndex int
AS

BEGIN
	DECLARE @StudentDetailsTable rules.IdStringTable;

	IF @schoolid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SCHOOL LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE @schoolid = sch.SchoolId
		;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE s.StudentUSI IN (SELECT ssa2.StudentUSI FROM edfi.StudentSchoolAssociation ssa2 WHERE ssa2.SchoolId = @schoolid) AND sch.SchoolId != @schoolid
			GROUP BY s.StudentUniqueId
			HAVING COUNT(1) > 0
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE s.StudentUSI IN (SELECT ssa2.StudentUSI FROM edfi.StudentSchoolAssociation ssa2 INNER JOIN edfi.School sch2 ON sch2.SchoolId = ssa2.SchoolId WHERE sch2.SchoolId = @schoolid)
			GROUP BY s.StudentUniqueId
			HAVING COUNT(eorg.EducationOrganizationId) > 1
			;
		END
	END

	IF @distid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- DISTRICT LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE @distid = eorgdist.EducationOrganizationId
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			GROUP BY s.StudentUniqueId, eorgdist.EducationOrganizationId
			HAVING COUNT(ssa.SchoolId) > 1 AND eorgdist.EducationOrganizationId = @distid
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
				LEFT OUTER JOIN edfi.EducationOrganization selecteddist ON selecteddist.EducationOrganizationId = @distid
			GROUP BY s.StudentUniqueId
			HAVING COUNT(eorgdist.EducationOrganizationId) > 1 AND COUNT(selecteddist.EducationOrganizationId) > 0
			;
		END
	END

	IF @distid IS NULL AND @schoolid IS NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			GROUP BY s.StudentUniqueId, eorgdist.EducationOrganizationId
			HAVING COUNT(ssa.SchoolId) > 1 
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			GROUP BY s.StudentUniqueId
			HAVING COUNT(eorgdist.EducationOrganizationId) > 1 
			;
		END
	END

	SELECT DISTINCT * FROM rules.GetStudentEnrollmentDetails(@StudentDetailsTable) enr ORDER BY enr.StudentId;
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Student Programs --------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.StudentProgramsReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.StudentProgramsReport;  
GO  

CREATE PROCEDURE [rules].[StudentProgramsReport]
	@distid int
AS

BEGIN
	DECLARE @StudentProgramsTable TABLE (
		OrgType INT,  -- 100 = SCHOOL, 200 = DISTRICT, 300 = STATE
		EdOrgId INT,
		SchoolName nvarchar(255),
		DistrictEdOrgId int,
		DistrictName nvarchar(255),
		DistinctEnrollmentCount int,
		DistinctDemographicsCount int,
		ADParentCount int,
		IndianNativeCount int,
		MigrantCount int,
		HomelessCount int,
		ImmigrantCount int,
		RecentEnglishCount int,
		SLIFECount int,
		EnglishLearnerIdentifiedCount int,
		EnglishLearnerServedCount int,
		IndependentStudyCount int,
		Section504Count int,
		Title1PartACount int,
		FreeReducedCount int
	);

	IF @distid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SCHOOL LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
		-- REGARDLESS of whether they have any enrollments or demographics.
		INSERT INTO @StudentProgramsTable(
			OrgType, 
			EdOrgId, 
			SchoolName, 
			DistrictEdOrgId, 
			DistrictName, 
			DistinctEnrollmentCount, 
			DistinctDemographicsCount,
			ADParentCount,
			IndianNativeCount,
			MigrantCount,
			HomelessCount,
			ImmigrantCount,
			RecentEnglishCount,
			SLIFECount,
			EnglishLearnerIdentifiedCount,
			EnglishLearnerServedCount,
			IndependentStudyCount,
			Section504Count,
			Title1PartACount,
			FreeReducedCount)
			SELECT 
				100, -- SCHOOL LEVEL
				eorg.EducationOrganizationId AS EdOrgId,
				eorg.NameOfInstitution As SchoolName,
				eorgdist.EducationOrganizationId AS DistrictEdOrgId,
				eorgdist.NameOfInstitution AS DistrictName,
				DistinctEnrollmentCount = enr_distinct.quantity,
				DistinctDemographicsCount = dem_distinct.quantity,
				ADParentCount = adparent.quantity,
				IndianNativeCount = amindian.quantity,
				MigrantCount = migrant.quantity,
				HomelessCount = homeless.quantity,
				ImmigrantCount = immigrant.quantity,
				RecentEnglish = recenteng.quantity,
				SLIFECount = slife.quantity,
				EnglishLearnerIdentifiedCount = limitedeng.quantity,
				EnglishLearnerServedCount = engserved.quantity,
				IndependentStudyCount = independ.quantity,
				Section504Count = sec504.quantity,
				Title1PartACount = title1.quantity,
				FreeReducedCount = mealselig.quantity
			FROM 
				edfi.School sch 
				LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
				LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
				LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId 
				-- To include duplicates (multiple records per student), use COUNT(1) instead
				OUTER APPLY (SELECT COUNT(DISTINCT ssa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
					WHERE ssa.SchoolId = eorg.EducationOrganizationId) enr_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId) dem_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Active Duty Parent (ADP)') adparent
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'American Indian - Alaskan Native (Minnesota)') amindian
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Migrant') migrant
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Homeless') homeless
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Immigrant') immigrant
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Recently Arrived English Learner (RAEL)') recenteng
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'SLIFE') slife
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue LIKE 'Limited%') limitedeng
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'English Learner Served') engserved
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Independent Study') independ
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Section 504 Placement') sec504
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Title I Part A') title1
				OUTER APPLY (SELECT COUNT(DISTINCT s.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = s.SchoolFoodServicesEligibilityDescriptorId
					WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND (d.ShortDescription LIKE 'reduced' OR d.ShortDescription LIKE 'free')) mealselig				
			WHERE @distid = eorgdist.EducationOrganizationId
			GROUP BY 
				eorg.EducationOrganizationId, 
				eorg.NameOfInstitution, 
				eorgdist.EducationOrganizationId, 
				eorgdist.NameOfInstitution,
				enr_distinct.quantity, 
				dem_distinct.quantity,
				adparent.quantity,
				amindian.quantity,
				migrant.quantity,
				homeless.quantity,
				immigrant.quantity,
				recenteng.quantity,
				slife.quantity,
				limitedeng.quantity,
				engserved.quantity,
				independ.quantity,
				sec504.quantity,
				title1.quantity,
				mealselig.quantity
		;
	END

	----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- DISTRICT LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
	-- REGARDLESS of whether they have any enrollments or demographics.
	INSERT INTO @StudentProgramsTable(
		OrgType, 
		EdOrgId, 
		SchoolName,      -- Actually, the District name needed here.
		DistrictEdOrgId, -- NULL for District Level
		DistrictName,    -- NULL for District Level
		DistinctEnrollmentCount, 
		DistinctDemographicsCount,
		ADParentCount,
		IndianNativeCount,
		MigrantCount,
		HomelessCount,
		ImmigrantCount,
		RecentEnglishCount,
		SLIFECount,
		EnglishLearnerIdentifiedCount,
		EnglishLearnerServedCount,
		IndependentStudyCount,
		Section504Count,
		Title1PartACount,
		FreeReducedCount)
		SELECT 
			200, -- DISTRICT LEVEL
			eorgdist.EducationOrganizationId AS DistrictEdOrgId,
			eorgdist.NameOfInstitution AS DistrictName,
			NULL,
			NULL,
			DistinctEnrollmentCount = enr_distinct.quantity,
			DistinctDemographicsCount = dem_distinct.quantity,
			ADParentCount = adparent.quantity,
			IndianNativeCount = amindian.quantity,
			MigrantCount = migrant.quantity,
			HomelessCount = homeless.quantity,
			ImmigrantCount = immigrant.quantity,
			RecentEnglish = recenteng.quantity,
			SLIFECount = slife.quantity,
			EnglishLearnerIdentifiedCount = limitedeng.quantity,
			EnglishLearnerServedCount = engserved.quantity,
			IndependentStudyCount = independ.quantity,
			Section504Count = sec504.quantity,
			Title1PartACount = title1.quantity,
			FreeReducedCount = mealselig.quantity
		FROM 
			edfi.EducationOrganization eorgdist 
			INNER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = eorgdist.EducationOrganizationId
			-- To include duplicates (multiple records per student), use COUNT(1) instead
			OUTER APPLY (SELECT COUNT(DISTINCT ssa.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON ssa.SchoolId = sch.SchoolId
				WHERE sch.LocalEducationAgencyId = eorgdist.EducationOrganizationId) enr_distinct
			OUTER APPLY (SELECT COUNT(DISTINCT seoa.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON sch.SchoolId = seoa.EducationOrganizationId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId)) dem_distinct
			OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Active Duty Parent (ADP)') adparent
			OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'American Indian - Alaskan Native (Minnesota)') amindian
			OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Migrant') migrant
			OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Homeless') homeless
			OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Immigrant') immigrant
			OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Recently Arrived English Learner (RAEL)') recenteng
			OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'SLIFE') slife
			OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue LIKE 'Limited%') limitedeng
			OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'English Learner Served') engserved
			OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Independent Study') independ
			OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Section 504 Placement') sec504
			OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
				WHERE eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND d.CodeValue = 'Title I Part A') title1
			OUTER APPLY (SELECT COUNT(DISTINCT s.StudentUSI) AS quantity 
				FROM edfi.Student s 
				LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
				LEFT OUTER JOIN edfi.School sch ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = s.SchoolFoodServicesEligibilityDescriptorId
				WHERE  eorgdist.EducationOrganizationId IN (seoa.EducationOrganizationId, sch.LocalEducationAgencyId) AND (d.ShortDescription LIKE 'reduced' OR d.ShortDescription LIKE 'free')) mealselig
		WHERE @distid = eorgdist.EducationOrganizationId OR @distid IS NULL
		GROUP BY 
			eorgdist.EducationOrganizationId, 
			eorgdist.NameOfInstitution,
			enr_distinct.quantity, 
			dem_distinct.quantity,
			adparent.quantity,
			amindian.quantity,
			migrant.quantity,
			homeless.quantity,
			immigrant.quantity,
			recenteng.quantity,
			slife.quantity,
			limitedeng.quantity,
			engserved.quantity,
			independ.quantity,
			sec504.quantity,
			title1.quantity,
			mealselig.quantity
	;

	IF @distid IS NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
		-- REGARDLESS of whether they have any enrollments or demographics.
		INSERT INTO @StudentProgramsTable(
			OrgType, 
			EdOrgId, 
			SchoolName,      -- Actually, the District name needed here.
			DistrictEdOrgId, -- NULL for District Level
			DistrictName,    -- NULL for District Level
			DistinctEnrollmentCount, 
			DistinctDemographicsCount,
			ADParentCount,
			IndianNativeCount,
			MigrantCount,
			HomelessCount,
			ImmigrantCount,
			RecentEnglishCount,
			SLIFECount,
			EnglishLearnerIdentifiedCount,
			EnglishLearnerServedCount,
			IndependentStudyCount,
			Section504Count,
			Title1PartACount,
			FreeReducedCount)
			SELECT 
				300, -- STATE LEVEL
				NULL AS DistrictEdOrgId,
				'State of Minnesota' AS SchoolName,
				NULL,
				NULL,
				DistinctEnrollmentCount = enr_distinct.quantity,
				DistinctDemographicsCount = dem_distinct.quantity,
				ADParentCount = adparent.quantity,
				IndianNativeCount = amindian.quantity,
				MigrantCount = migrant.quantity,
				HomelessCount = homeless.quantity,
				ImmigrantCount = immigrant.quantity,
				RecentEnglish = recenteng.quantity,
				SLIFECount = slife.quantity,
				EnglishLearnerIdentifiedCount = limitedeng.quantity,
				EnglishLearnerServedCount = engserved.quantity,
				IndependentStudyCount = independ.quantity,
				Section504Count = sec504.quantity,
				Title1PartACount = title1.quantity,
				FreeReducedCount = mealselig.quantity
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				-- To include duplicates (multiple records per student), use COUNT(1) instead
				OUTER APPLY (SELECT COUNT(DISTINCT ssa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentSchoolAssociation ssa ON ssa.StudentUSI = s.StudentUSI) enr_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoa.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI) dem_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoar.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationRace seoar ON seoar.StudentUSI = s.StudentUSI) rac_distinct
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE d.CodeValue = 'Active Duty Parent (ADP)') adparent
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE d.CodeValue = 'American Indian - Alaskan Native (Minnesota)') amindian
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE d.CodeValue = 'Migrant') migrant
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE d.CodeValue = 'Homeless') homeless
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE d.CodeValue = 'Immigrant') immigrant
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE d.CodeValue = 'Recently Arrived English Learner (RAEL)') recenteng
				OUTER APPLY (SELECT COUNT(DISTINCT seoasc.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
					WHERE d.CodeValue = 'SLIFE') slife
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE d.CodeValue LIKE 'Limited%') limitedeng
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE d.CodeValue = 'English Learner Served') engserved
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE d.CodeValue = 'Independent Study') independ
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE d.CodeValue = 'Section 504 Placement') sec504
				OUTER APPLY (SELECT COUNT(DISTINCT ssaspp.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
					WHERE d.CodeValue = 'Title I Part A') title1
				OUTER APPLY (SELECT COUNT(DISTINCT s.StudentUSI) AS quantity 
					FROM edfi.Student s 
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.StudentUSI = s.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = s.SchoolFoodServicesEligibilityDescriptorId
					WHERE (d.ShortDescription LIKE 'reduced' OR d.ShortDescription LIKE 'free')) mealselig
			GROUP BY 
				enr_distinct.quantity, 
				dem_distinct.quantity,
				adparent.quantity,
				amindian.quantity,
				migrant.quantity,
				homeless.quantity,
				immigrant.quantity,
				recenteng.quantity,
				slife.quantity,
				limitedeng.quantity,
				engserved.quantity,
				independ.quantity,
				sec504.quantity,
				title1.quantity,
				mealselig.quantity
		;
	END

	SELECT * FROM @StudentProgramsTable ORDER BY OrgType DESC, SchoolName;
END

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Student Programs - Student Details --------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.StudentProgramsStudentDetailsReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.StudentProgramsStudentDetailsReport;  
GO  

CREATE PROCEDURE [rules].[StudentProgramsStudentDetailsReport]
	@schoolid int,
	@distid int,
	@columnIndex int
AS

BEGIN
DECLARE @StudentDetailsTable rules.IdStringTable;

	IF @schoolid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- SCHOOL LEVEL ------------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE sch.SchoolId = @schoolid
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
			WHERE sch.SchoolId = @schoolid
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Active Duty Parent (ADP)'
		END
		IF @columnIndex = 3
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'American Indian - Alaskan Native (Minnesota)'
		END
		IF @columnIndex = 4
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Migrant'
		END
		IF @columnIndex = 5
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Homeless'
		END
		IF @columnIndex = 6
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Immigrant'
		END
		IF @columnIndex = 7
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Recently Arrived English Learner (RAEL)'
		END
		IF @columnIndex = 8
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'SLIFE'
		END
		IF @columnIndex = 9
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue LIKE 'Limited%'
		END
		IF @columnIndex = 10
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'English Learner Served'
		END
		IF @columnIndex = 11
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Independent Study'
		END
		IF @columnIndex = 12
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Section 504 Placement'
		END
		IF @columnIndex = 13
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorg.EducationOrganizationId = eorg.EducationOrganizationId AND d.CodeValue = 'Title I Part A'
		END
		IF @columnIndex = 14
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoa.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = st.SchoolFoodServicesEligibilityDescriptorId
			WHERE seoa.EducationOrganizationId = eorg.EducationOrganizationId AND (d.ShortDescription LIKE 'reduced' OR d.ShortDescription LIKE 'free')
		END
	END

	If @distid IS NOT NULL
	BEGIN
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- DISTRICT LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------

		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE eorgdist.EducationOrganizationId = @distid
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
			WHERE eorgdist.EducationOrganizationId = @distid
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Active Duty Parent (ADP)'
		END
		IF @columnIndex = 3
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'American Indian - Alaskan Native (Minnesota)'
		END
		IF @columnIndex = 4
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Migrant'
		END
		IF @columnIndex = 5
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Homeless'
		END
		IF @columnIndex = 6
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Immigrant'
		END
		IF @columnIndex = 7
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Recently Arrived English Learner (RAEL)'
		END
		IF @columnIndex = 8
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'SLIFE'
		END
		IF @columnIndex = 9
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue LIKE 'Limited%'
		END
		IF @columnIndex = 10
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'English Learner Served'
		END
		IF @columnIndex = 11
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Independent Study'
		END
		IF @columnIndex = 12
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Section 504 Placement'
		END
		IF @columnIndex = 13
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Title I Part A'
		END
		IF @columnIndex = 14
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoa.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = st.SchoolFoodServicesEligibilityDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND (d.ShortDescription LIKE 'reduced' OR d.ShortDescription LIKE 'free')
		END
	END

	IF @distid IS NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		IF @columnIndex = 0
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentSchoolAssociation ssa ON ssa.SchoolId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON s.StudentUSI = ssa.StudentUSI
			WHERE eorgdist.EducationOrganizationId = @distid
			;
		END
		IF @columnIndex = 1
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT s.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorgdist 
				LEFT OUTER JOIN edfi.School sch ON sch.LocalEducationAgencyId  = eorgdist.EducationOrganizationId
				INNER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId
				LEFT OUTER JOIN edfi.Student s ON seoa.StudentUSI = s.StudentUSI
			WHERE eorgdist.EducationOrganizationId = @distid
			;
		END
		IF @columnIndex = 2
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Active Duty Parent (ADP)'
		END
		IF @columnIndex = 3
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'American Indian - Alaskan Native (Minnesota)'
		END
		IF @columnIndex = 4
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Migrant'
		END
		IF @columnIndex = 5
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Homeless'
		END
		IF @columnIndex = 6
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Immigrant'
		END
		IF @columnIndex = 7
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Recently Arrived English Learner (RAEL)'
		END
		IF @columnIndex = 8
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentEducationOrganizationAssociationStudentCharacteristic seoasc ON seoasc.EducationOrganizationId = eorg.EducationOrganizationId
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoasc.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = seoasc.StudentCharacteristicDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'SLIFE'
		END
		IF @columnIndex = 9
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue LIKE 'Limited%'
		END
		IF @columnIndex = 10
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'English Learner Served'
		END
		IF @columnIndex = 11
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Independent Study'
		END
		IF @columnIndex = 12
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Section 504 Placement'
		END
		IF @columnIndex = 13
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN extension.StudentSchoolAssociationStudentProgramParticipation ssaspp ON ssaspp.SchoolId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = ssaspp.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = ssaspp.ProgramCategoryDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND d.CodeValue = 'Title I Part A'
		END
		IF @columnIndex = 14
		BEGIN
			INSERT INTO @StudentDetailsTable(IdNumber)
			SELECT DISTINCT st.StudentUniqueId
			FROM 
				edfi.School sch 
					LEFT OUTER JOIN edfi.EducationOrganization eorg ON eorg.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.LocalEducationAgency lea ON lea.LocalEducationAgencyId = sch.LocalEducationAgencyId 
					LEFT OUTER JOIN edfi.EducationOrganization eorgdist ON eorgdist.EducationOrganizationId = lea.LocalEducationAgencyId
					LEFT OUTER JOIN edfi.StudentEducationOrganizationAssociation seoa ON seoa.EducationOrganizationId = sch.SchoolId 
					LEFT OUTER JOIN edfi.Student st ON st.StudentUSI = seoa.StudentUSI
					LEFT OUTER JOIN edfi.Descriptor d ON d.DescriptorId = st.SchoolFoodServicesEligibilityDescriptorId
			WHERE eorgdist.EducationOrganizationId = @distid AND (d.ShortDescription LIKE 'reduced' OR d.ShortDescription LIKE 'free')
		END
	END

	SELECT DISTINCT * FROM rules.GetStudentEnrollmentDetails(@StudentDetailsTable) enr ORDER BY enr.StudentId;
END

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Change of Enrollment  ------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.ChangeOfEnrollment', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.ChangeOfEnrollment;  
GO  

CREATE PROCEDURE [rules].ChangeOfEnrollment
	@distid int
AS

BEGIN
	DECLARE @ChangeOfEnrollmentTable TABLE (
		IsCurrentDistrict bit,
		CurrentDistEdOrgId int,
		CurrentDistrictName varchar(255),
		CurrentSchoolEdOrgId int,
		CurrentSchoolName varchar(255),
		CurrentEdOrgEnrollmentDate datetime,
		CurrentEdOrgExitDate datetime,
		CurrentGrade varchar(255),
		PastDistEdOrgId int,
		PastDistrictName varchar(255),
		PastSchoolEdOrgId int,
		PastSchoolName varchar(255),
		PastEdOrgEnrollmentDate datetime,
		PastEdOrgExitDate datetime,
		PastGrade varchar(255),
		StudentID varchar(255),
		StudentLastName varchar(255),
		StudentFirstName varchar(255),
		StudentMiddleName varchar(255),
		StudentBirthDate datetime
	);
	DECLARE @ThirtyDaysAgo datetime = DATEADD(DAY, -30, GETDATE());

	IF @distid IS NOT NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- As Current District  ----------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		INSERT INTO @ChangeOfEnrollmentTable(
			IsCurrentDistrict,
			CurrentDistEdOrgId,
			CurrentDistrictName,
			CurrentSchoolEdOrgId,
			CurrentSchoolName,
			CurrentEdOrgEnrollmentDate,
			CurrentEdOrgExitDate,
			CurrentGrade,
			PastDistEdOrgId,
			PastDistrictName,
			PastSchoolEdOrgId,
			PastSchoolName,
			PastEdOrgEnrollmentDate,
			PastEdOrgExitDate,
			PastGrade,
			StudentID,
			StudentLastName,
			StudentFirstName,
			StudentMiddleName,
			StudentBirthDate
			)
			SELECT 
				1, -- Gaining/Current School Enrollment
				currdisteorg.EducationOrganizationId,
				currdisteorg.NameOfInstitution,
				currschedorg.EducationOrganizationId,
				currschedorg.NameOfInstitution,
				currssa.EntryDate,
				currssa.ExitWithdrawDate,
				currgld.CodeValue,
				pastdisteorg.EducationOrganizationId,
				pastdisteorg.NameOfInstitution,
				pastschedorg.EducationOrganizationId,
				pastschedorg.NameOfInstitution,
				pastssa.EntryDate,
				pastssa.ExitWithdrawDate,
				pastgld.CodeValue,
				st.StudentUniqueId,
				st.LastSurname,
				st.FirstName,
				st.MiddleName,
				st.BirthDate
			FROM 
				edfi.EducationOrganization currdisteorg 
				INNER JOIN edfi.School currsch ON currsch.LocalEducationAgencyId = currdisteorg.EducationOrganizationId 
				LEFT OUTER JOIN edfi.EducationOrganization currschedorg ON currschedorg.EducationOrganizationId = currsch.SchoolId
				INNER JOIN edfi.StudentSchoolAssociation currssa ON currssa.SchoolId = currsch.SchoolId
				LEFT OUTER JOIN edfi.Descriptor currgld ON currssa.EntryGradeLevelDescriptorId = currgld.DescriptorId
				INNER JOIN edfi.Student st ON st.StudentUSI = currssa.StudentUSI
				INNER JOIN edfi.StudentSchoolAssociation pastssa ON pastssa.StudentUSI = st.StudentUSI AND pastssa.SchoolId != currsch.SchoolId
				LEFT OUTER JOIN edfi.Descriptor pastgld ON pastssa.EntryGradeLevelDescriptorId = pastgld.DescriptorId
				INNER JOIN edfi.School pastsch ON pastssa.SchoolId = pastsch.SchoolId
				LEFT OUTER JOIN edfi.EducationOrganization pastschedorg ON pastschedorg.EducationOrganizationId = pastsch.SchoolId
				INNER JOIN edfi.EducationOrganization pastdisteorg ON pastdisteorg.EducationOrganizationId = pastsch.LocalEducationAgencyId
			WHERE @distid = currdisteorg.EducationOrganizationId
				AND currssa.EntryDate IS NOT NULL 
				AND currssa.EntryDate > @ThirtyDaysAgo
				AND pastssa.EntryDate < @ThirtyDaysAgo
		;

		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- As Past District  ----------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- The ONLY TWO DIFFERENCES from the above SQL statement are the IsCurrentDistrict = 0 and the WHERE clause.
		INSERT INTO @ChangeOfEnrollmentTable(
			IsCurrentDistrict,
			CurrentDistEdOrgId,
			CurrentDistrictName,
			CurrentSchoolEdOrgId,
			CurrentSchoolName,
			CurrentEdOrgEnrollmentDate,
			CurrentEdOrgExitDate,
			CurrentGrade,
			PastDistEdOrgId,
			PastDistrictName,
			PastSchoolEdOrgId,
			PastSchoolName,
			PastEdOrgEnrollmentDate,
			PastEdOrgExitDate,
			PastGrade,
			StudentID,
			StudentLastName,
			StudentFirstName,
			StudentMiddleName,
			StudentBirthDate
			)
			SELECT 
				0, -- Gaining/Current School Enrollment
				currdisteorg.EducationOrganizationId,
				currdisteorg.NameOfInstitution,
				currschedorg.EducationOrganizationId,
				currschedorg.NameOfInstitution,
				currssa.EntryDate,
				currssa.ExitWithdrawDate,
				currgld.CodeValue,
				pastdisteorg.EducationOrganizationId,
				pastdisteorg.NameOfInstitution,
				pastschedorg.EducationOrganizationId,
				pastschedorg.NameOfInstitution,
				pastssa.EntryDate,
				pastssa.ExitWithdrawDate,
				pastgld.CodeValue,
				st.StudentUniqueId,
				st.LastSurname,
				st.FirstName,
				st.MiddleName,
				st.BirthDate
			FROM 
				edfi.EducationOrganization currdisteorg 
				INNER JOIN edfi.School currsch ON currsch.LocalEducationAgencyId = currdisteorg.EducationOrganizationId 
				LEFT OUTER JOIN edfi.EducationOrganization currschedorg ON currschedorg.EducationOrganizationId = currsch.SchoolId
				INNER JOIN edfi.StudentSchoolAssociation currssa ON currssa.SchoolId = currsch.SchoolId
				LEFT OUTER JOIN edfi.Descriptor currgld ON currssa.EntryGradeLevelDescriptorId = currgld.DescriptorId
				INNER JOIN edfi.Student st ON st.StudentUSI = currssa.StudentUSI
				INNER JOIN edfi.StudentSchoolAssociation pastssa ON pastssa.StudentUSI = st.StudentUSI AND pastssa.SchoolId != currsch.SchoolId
				LEFT OUTER JOIN edfi.Descriptor pastgld ON pastssa.EntryGradeLevelDescriptorId = pastgld.DescriptorId
				INNER JOIN edfi.School pastsch ON pastssa.SchoolId = pastsch.SchoolId
				LEFT OUTER JOIN edfi.EducationOrganization pastschedorg ON pastschedorg.EducationOrganizationId = pastsch.SchoolId
				INNER JOIN edfi.EducationOrganization pastdisteorg ON pastdisteorg.EducationOrganizationId = pastsch.SchoolId
			WHERE @distid = pastdisteorg.EducationOrganizationId
				AND currssa.EntryDate IS NOT NULL 
				AND currssa.EntryDate > @ThirtyDaysAgo
				AND pastssa.ExitWithdrawDate > @ThirtyDaysAgo
		;
	END

	SELECT * FROM @ChangeOfEnrollmentTable ORDER BY StudentLastName, StudentFirstName, StudentMiddleName;

END

GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  Residents Enrolled Elsewhere  ------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.ResidentsEnrolledElsewhereReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.ResidentsEnrolledElsewhereReport;  
GO  

CREATE PROCEDURE [rules].[ResidentsEnrolledElsewhereReport]
	@distid int
AS

BEGIN
	DECLARE @ResidentsEnrolledElsewhereTable TABLE (
		OrgType int,  -- 100 = SCHOOL, 200 = DISTRICT, 300 = STATE
		EdOrgId int,
		EdOrgName nvarchar(255),
		DistrictOfEnrollmentId int,
		DistrictOfEnrollmentName nvarchar(255),
		ResidentsEnrolled int
	);


	----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- DISTRICT LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
	-- REGARDLESS of whether they have any enrollments or demographics.
	INSERT INTO @ResidentsEnrolledElsewhereTable(
		OrgType, 
		EdOrgId, 
		EdOrgName,
		DistrictOfEnrollmentId, 
		DistrictOfEnrollmentName, 
		ResidentsEnrolled)
		SELECT DISTINCT
			200, -- DISTRICT LEVEL
			eorghomedist.EducationOrganizationId,
			eorghomedist.NameOfInstitution,
			otherdisteorg.EducationOrganizationId,
			otherdisteorg.NameOfInstitution,
			COUNT(1)
		FROM 
			edfi.EducationOrganization eorghomedist 
			INNER JOIN edfi.School homesch ON homesch.LocalEducationAgencyId = eorghomedist.EducationOrganizationId
			INNER JOIN extension.StudentSchoolAssociationExtension homessae ON homessae.SchoolId = homesch.SchoolId AND homessae.ResidentLocalEducationAgencyId = @distid
			INNER JOIN edfi.Student st ON st.StudentUSI = homessae.StudentUSI
			-- We have all the students in the home district, find districts where the student is enrolled outside this district
			INNER JOIN edfi.StudentSchoolAssociation otherssa ON otherssa.StudentUSI = st.StudentUSI
			INNER JOIN edfi.School othersch ON othersch.SchoolId = otherssa.SchoolId
			INNER JOIN edfi.EducationOrganization otherdisteorg ON otherdisteorg.EducationOrganizationId = othersch.LocalEducationAgencyId
		WHERE @distid = eorghomedist.EducationOrganizationId AND eorghomedist.EducationOrganizationId != othersch.LocalEducationAgencyId
		GROUP BY 
			eorghomedist.EducationOrganizationId,
			eorghomedist.NameOfInstitution,
			otherdisteorg.EducationOrganizationId,
			otherdisteorg.NameOfInstitution
	;

	IF @distid IS NULL
	BEGIN

		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------

		-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
		-- REGARDLESS of whether they have any enrollments or demographics.
		INSERT INTO @ResidentsEnrolledElsewhereTable(
			OrgType, 
			EdOrgId, 
			EdOrgName,
			DistrictOfEnrollmentId, 
			DistrictOfEnrollmentName, 
			ResidentsEnrolled)
			SELECT DISTINCT
				300, -- STATE LEVEL
				eorghomedist.EducationOrganizationId,
				eorghomedist.NameOfInstitution,
				otherdisteorg.EducationOrganizationId,
				otherdisteorg.NameOfInstitution,
				COUNT(1)
			FROM 
				edfi.EducationOrganization eorghomedist 
				INNER JOIN edfi.School homesch ON homesch.LocalEducationAgencyId = eorghomedist.EducationOrganizationId
				INNER JOIN extension.StudentSchoolAssociationExtension homessae ON homessae.SchoolId = homesch.SchoolId
				INNER JOIN edfi.Student st ON st.StudentUSI = homessae.StudentUSI
				-- We have all the students in the home district, find districts where the student is enrolled outside this district
				INNER JOIN edfi.StudentSchoolAssociation otherssa ON otherssa.StudentUSI = st.StudentUSI
				INNER JOIN edfi.School othersch ON othersch.SchoolId = otherssa.SchoolId
				INNER JOIN edfi.EducationOrganization otherdisteorg ON otherdisteorg.EducationOrganizationId = othersch.LocalEducationAgencyId
			WHERE eorghomedist.EducationOrganizationId != othersch.LocalEducationAgencyId
			GROUP BY 
				eorghomedist.EducationOrganizationId,
				eorghomedist.NameOfInstitution,
				otherdisteorg.EducationOrganizationId,
				otherdisteorg.NameOfInstitution
		;
	END

	SELECT * FROM @ResidentsEnrolledElsewhereTable ORDER BY DistrictOfEnrollmentName;
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- PROCEDURE:  RESIDENTS ENROLLED DRILL DOWN -------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ( 'rules.ResidentsEnrolledElsewhereStudentDetailsReport', 'P' ) IS NOT NULL   
    DROP PROCEDURE rules.ResidentsEnrolledElsewhereStudentDetailsReport;  
GO  

CREATE PROCEDURE [rules].ResidentsEnrolledElsewhereStudentDetailsReport
	@distid int
AS

BEGIN
	DECLARE @ResidentsEnrolledElsewhereStudentDetailsTable rules.IdStringTable;


	----------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- DISTRICT LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------

	-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
	-- REGARDLESS of whether they have any enrollments or demographics.
	INSERT INTO @ResidentsEnrolledElsewhereStudentDetailsTable(IdNumber)
		SELECT 
			DISTINCT st.StudentUniqueId
		FROM 
			edfi.EducationOrganization eorghomedist 
			INNER JOIN edfi.School homesch ON homesch.LocalEducationAgencyId = eorghomedist.EducationOrganizationId
			INNER JOIN extension.StudentSchoolAssociationExtension homessae ON homessae.SchoolId = homesch.SchoolId AND homessae.ResidentLocalEducationAgencyId = @distid
			INNER JOIN edfi.Student st ON st.StudentUSI = homessae.StudentUSI
			-- We have all the students in the home district, find districts where the student is enrolled outside this district
			INNER JOIN edfi.StudentSchoolAssociation otherssa ON otherssa.StudentUSI = st.StudentUSI
			INNER JOIN edfi.School othersch ON othersch.SchoolId = otherssa.SchoolId
			INNER JOIN edfi.EducationOrganization otherdisteorg ON otherdisteorg.EducationOrganizationId = othersch.LocalEducationAgencyId
		WHERE @distid = eorghomedist.EducationOrganizationId AND eorghomedist.EducationOrganizationId != othersch.LocalEducationAgencyId
	;

	IF @distid IS NULL
	BEGIN
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- STATE LEVEL ----------------------------------------------------------------------------------------------------------------------------------------------------
		----------------------------------------------------------------------------------------------------------------------------------------------------------------------

		-- Load School information, rolling up to District - if District is NULL, then ALL Districts in the State.
		-- REGARDLESS of whether they have any enrollments or demographics.
		INSERT INTO @ResidentsEnrolledElsewhereStudentDetailsTable(IdNumber)
			SELECT 
				DISTINCT st.StudentUniqueId
			FROM 
				edfi.EducationOrganization eorghomedist 
				INNER JOIN edfi.School homesch ON homesch.LocalEducationAgencyId = eorghomedist.EducationOrganizationId
				INNER JOIN extension.StudentSchoolAssociationExtension homessae ON homessae.SchoolId = homesch.SchoolId
				INNER JOIN edfi.Student st ON st.StudentUSI = homessae.StudentUSI
				-- We have all the students in the home district, find districts where the student is enrolled outside this district
				INNER JOIN edfi.StudentSchoolAssociation otherssa ON otherssa.StudentUSI = st.StudentUSI
				INNER JOIN edfi.School othersch ON othersch.SchoolId = otherssa.SchoolId
				INNER JOIN edfi.EducationOrganization otherdisteorg ON otherdisteorg.EducationOrganizationId = othersch.LocalEducationAgencyId
			WHERE eorghomedist.EducationOrganizationId != othersch.LocalEducationAgencyId
			;
	END

	SELECT DISTINCT * FROM rules.GetStudentEnrollmentDetails(@ResidentsEnrolledElsewhereStudentDetailsTable) enr ORDER BY enr.StudentId;
END

GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ContainsDoubleSpace'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].[ContainsDoubleSpace]
GO

CREATE FUNCTION rules.ContainsDoubleSpace (@String VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @DoubleSpace AS BIT

SELECT @DoubleSpace = 
	   CASE
		WHEN CHARINDEX('  ',@String) > 0 THEN 1
		ELSE 0
	   END
RETURN @DoubleSpace;

END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ContainsInvalidChar'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].ContainsInvalidChar
GO

CREATE FUNCTION rules.ContainsInvalidChar
(
	@String AS VARCHAR(200)
)
RETURNS VARCHAR(200)
AS  
BEGIN

   IF LEN(LTRIM(RTRIM(@String)))>0
   BEGIN
	DECLARE @InvalidChar VARCHAR(200)	
	DECLARE @Index INT
	DECLARE @ASCIIChar INT

	SET @Index = 1
	SET @InvalidChar=0
	BEGIN     	 
      		WHILE @Index <= LEN(@String)
		BEGIN
    		SET @ASCIIChar=ASCII(SUBSTRING(@String, @Index, 1))
    		IF NOT @ASCIIChar BETWEEN 65 AND 90
		AND NOT @ASCIIChar BETWEEN 97 AND 122 
		AND NOT @ASCIIChar IN (32, 39, 45)
		SET @InvalidChar = 1
	        SET @Index = @Index + 1
    		END
	END    
   END
   ELSE
   BEGIN
	SET @InvalidChar = 0
   END

   RETURN (@InvalidChar)
END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ShortString'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].ShortString
GO

CREATE FUNCTION rules.ShortString (@String VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @ShortString AS BIT

SELECT @ShortString = 
	   CASE
		WHEN LEN(@String) < 2 THEN 1
		WHEN LEN(@String) = 2 AND (
			ASCII(SUBSTRING(@String,2,1)) NOT BETWEEN 65 AND 90 
		 OR ASCII(SUBSTRING(@String,2,1)) <> 39 
		 OR ASCII(SUBSTRING(@String,2,1)) NOT BETWEEN 97 AND 122
			) THEN 1
		ELSE 0 
	   END
RETURN @ShortString;

END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'StartsWithInvalidChar'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].StartsWithInvalidChar
GO

CREATE FUNCTION rules.StartsWithInvalidChar (@String VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @InvalidChar AS BIT

SELECT @InvalidChar = 
	   CASE
		WHEN @String IS NULL THEN 0
		WHEN (ASCII(LEFT(@String,1)) BETWEEN 65 and 90) THEN 0
		WHEN (ASCII(LEFT(@String,1)) BETWEEN 97 and 122) THEN 0
		ELSE 1
	   END
RETURN @InvalidChar;

END;


GO


IF EXISTS (SELECT * 
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_NAME = 'ValidMARSSNumberFormat'
			AND ROUTINE_SCHEMA = 'rules')
	DROP FUNCTION [rules].ValidMARSSNumberFormat
GO

CREATE FUNCTION rules.ValidMARSSNumberFormat (@MARSSNumber VARCHAR(200))

RETURNS BIT 

BEGIN

DECLARE @ValidMARSSNumber AS BIT

SELECT @ValidMARSSNumber = 
	   CASE
		WHEN @MARSSNumber LIKE '%[^0-9]%' THEN 0
		WHEN LEN(LTRIM(RTRIM(@MARSSNumber))) <> 13 THEN 0
		WHEN LEFT(@MARSSNumber,4) IN ('0000','5555') THEN 0
	   ELSE 1
	   END
RETURN @ValidMARSSNumber;

END;