﻿namespace ValidationWeb.Models
{
    public class RolePermissions
    {
        public bool CanAccessAdminFeatures { get; set; }

        public bool CanViewOdsReports { get; set; }

        public bool CanModifyRecordsRequests { get; set; }

        public bool CanViewStudentDrilldownReports { get; set; }

        public bool CanViewValidationReports { get; set; }

        public bool CanRunValidationReports { get; set; }

        public bool CanAccessAllDistrictsMode { get; set; }

        public bool CanViewStudentLevelReports { get; set; }
    }
}