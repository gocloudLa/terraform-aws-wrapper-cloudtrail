output "enabled" {
  description = "Whether the wrapper created CloudTrail resources."
  value       = module.wrapper_cloudtrail.enabled
}

output "trail_arn" {
  value = module.wrapper_cloudtrail.trail_arn
}

output "s3_bucket_id" {
  value = module.wrapper_cloudtrail.s3_bucket_id
}

output "kms_key_arn" {
  value = module.wrapper_cloudtrail.kms_key_arn
}

output "trail_name" {
  value = module.wrapper_cloudtrail.trail_name
}

output "cloudwatch_log_group_arn" {
  value = module.wrapper_cloudtrail.cloudwatch_log_group_arn
}
