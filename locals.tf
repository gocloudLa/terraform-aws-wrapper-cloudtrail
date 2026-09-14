locals {
  cloudtrail_enable = try(var.cloudtrail_parameters.enable, false) ? 1 : 0

  trail_name = try(var.cloudtrail_parameters.trail_name, "${local.common_name}-org-trail")

  organization_id = local.cloudtrail_enable == 1 ? data.aws_organizations_organization.this[0].id : null
}
