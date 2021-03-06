﻿using System.Web.Mvc;

namespace ValidationWeb.Filters
{
    public class PortalAuthorize : AuthorizeAttribute
    {
        public override void OnAuthorization(AuthorizationContext filterContext)
        {
            // If they are authorized, handle accordingly
            if (AuthorizeCore(filterContext.HttpContext))
            {
                base.OnAuthorization(filterContext);
            }
            //else
            //{
            //    if (filterContext.HttpContext.User.IsInRole(PortalRoleNames.Admin) 
            //        && filterContext.ActionDescriptor.ControllerDescriptor.ControllerName != "Admin")
            //    {

            //        filterContext.Result = new RedirectToRouteResult(new RouteValueDictionary(new { controller = "Admin", action = "Index" }));
            //        filterContext.Result.ExecuteResult(filterContext.Controller.ControllerContext);
            //    }
            //}
        }
    }
}