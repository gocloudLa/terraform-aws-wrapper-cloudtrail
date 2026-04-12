module "kms" {
  source = "./modules/aws/terraform-aws-cloudtrail-kms"
  count  = local.cloudtrail_enable

  providers = { aws = aws.kms }

  description             = try(var.cloudtrail_parameters.kms.description, "KMS key for CloudTrail log encryption (${local.common_name})")
  deletion_window_in_days = try(var.cloudtrail_parameters.kms.deletion_window_in_days, 30)
  enable_key_rotation     = try(var.cloudtrail_parameters.kms.enable_key_rotation, true)
  alias_name              = try(var.cloudtrail_parameters.kms.alias_name, "alias/${local.common_name}-cloudtrail")
  tags                    = merge(local.common_tags, try(var.cloudtrail_parameters.tags, var.cloudtrail_defaults.tags, null))

  sec_account_id = data.aws_caller_identity.sec.account_id
  trail_name     = local.trail_name
  log_account_id = data.aws_caller_identity.log.account_id
  log_region     = data.aws_region.log.id
}

module "log_bucket" {
  source = "./modules/aws/terraform-aws-cloudtrail-log-bucket"
  count  = local.cloudtrail_enable

  providers = { aws = aws.log }

  bucket_name       = try(var.cloudtrail_parameters.log_bucket.bucket_name, "${local.common_name}-cloudtrail-logs-${data.aws_caller_identity.log.account_id}")
  force_destroy     = try(var.cloudtrail_parameters.log_bucket.force_destroy, false)
  enable_versioning = try(var.cloudtrail_parameters.log_bucket.enable_versioning, true)
  tags              = merge(local.common_tags, try(var.cloudtrail_parameters.tags, var.cloudtrail_defaults.tags, null))

  s3_key_prefix                      = try(var.cloudtrail_parameters.s3_key_prefix, "cloudtrail")
  organization_id                    = local.organization_id != null ? local.organization_id : ""
  enforce_s3_source_org_id_condition = try(var.cloudtrail_parameters.log_bucket.enforce_s3_source_org_id, false)
  enable_bucket_policy               = try(var.cloudtrail_parameters.log_bucket.enable_bucket_policy, true)
  cloudtrail_trail_arn_pattern       = "arn:aws:cloudtrail:*:${data.aws_caller_identity.sec.account_id}:trail/${local.trail_name}"
  kms_key_arn                        = module.kms[0].key_arn
  enable_sse_kms_default             = try(var.cloudtrail_parameters.log_bucket.enable_sse_kms_default, true)

  enable_server_access_logging = try(var.cloudtrail_parameters.log_bucket.enable_server_access_logging, false)
  access_logs_target_bucket    = try(var.cloudtrail_parameters.log_bucket.access_logs_target_bucket, "")
  access_logs_target_prefix    = try(var.cloudtrail_parameters.log_bucket.access_logs_target_prefix, "s3-access-logs/")

  lifecycle_glacier_transition_days = try(var.cloudtrail_parameters.log_bucket.lifecycle_glacier_transition_days, null)
  lifecycle_expiration_days         = try(var.cloudtrail_parameters.log_bucket.lifecycle_expiration_days, null)
}

module "organization_trail" {
  source = "./modules/aws/terraform-aws-cloudtrail-organization-trail"
  count  = local.cloudtrail_enable

  providers = { aws = aws }

  trail_name     = local.trail_name
  s3_bucket_name = module.log_bucket[0].bucket_id
  s3_key_prefix  = try(var.cloudtrail_parameters.s3_key_prefix, "cloudtrail")
  kms_key_id     = module.kms[0].key_arn
  tags           = merge(local.common_tags, try(var.cloudtrail_parameters.tags, var.cloudtrail_defaults.tags, null))

  enable_cloudwatch_logs        = try(var.cloudtrail_parameters.trail.enable_cloudwatch_logs, false)
  cloudwatch_log_group_name     = try(var.cloudtrail_parameters.trail.cloudwatch_log_group_name, "/aws/cloudtrail/${local.trail_name}")
  cloudwatch_log_retention_days = try(var.cloudtrail_parameters.trail.cloudwatch_log_retention_days, 90)
  event_selectors               = try(var.cloudtrail_parameters.trail.event_selectors, null)
  sns_topic_arn                 = try(var.cloudtrail_parameters.trail.sns_topic_arn, null)
}
