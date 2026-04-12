output "enabled" {
  description = "Whether CloudTrail resources were created (cloudtrail_parameters.enable)."
  value       = local.cloudtrail_enable == 1
}

output "trail_arn" {
  description = "ARN of the organization CloudTrail trail."
  value       = try(module.organization_trail[0].trail_arn, null)
}

output "trail_name" {
  description = "Name of the organization CloudTrail trail."
  value       = try(module.organization_trail[0].trail_name, null)
}

output "s3_bucket_id" {
  description = "Log archive S3 bucket name (log account)."
  value       = try(module.log_bucket[0].bucket_id, null)
}

output "kms_key_arn" {
  description = "KMS key ARN used for CloudTrail log encryption."
  value       = try(module.kms[0].key_arn, null)
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Logs group ARN when trail logging to CloudWatch is enabled; otherwise null."
  value       = try(module.organization_trail[0].cloudwatch_log_group_arn, null)
}
