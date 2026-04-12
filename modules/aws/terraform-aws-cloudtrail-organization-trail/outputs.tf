output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "trail_id" {
  description = "ID of the CloudTrail trail."
  value       = aws_cloudtrail.this.id
}

output "trail_name" {
  description = "Name of the CloudTrail trail."
  value       = aws_cloudtrail.this.name
}

output "home_region" {
  description = "Region in which the trail was created."
  value       = aws_cloudtrail.this.home_region
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group name when CloudWatch integration is enabled."
  value       = try(aws_cloudwatch_log_group.trail[0].name, null)
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch Logs group ARN when CloudWatch integration is enabled."
  value       = try(aws_cloudwatch_log_group.trail[0].arn, null)
}

output "cloudwatch_logs_role_arn" {
  description = "IAM role ARN used by CloudTrail to publish to CloudWatch Logs."
  value       = try(aws_iam_role.cloudtrail_cwl[0].arn, null)
}
