﻿using ValidationWeb.Models;

namespace ValidationWeb.ViewModels
{
    public class OdsResidentsEnrolledElsewhereReportViewModel
    {
        public ValidationPortalIdentity User { get; set; }

        public int EdOrgId { get; set; }
        
        public string EdOrgName { get; set; }
        
        public bool IsStateMode { get; set; }
        
        public string FourDigitSchoolYear { get; set; }
    }
}