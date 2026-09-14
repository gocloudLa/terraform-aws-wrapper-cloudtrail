variable "trail_name" {
  type        = string
  description = "Name of the CloudTrail trail."
}

variable "s3_bucket_name" {
  type        = string
  description = "Target S3 bucket for trail logs."
}

variable "s3_key_prefix" {
  type        = string
  description = "Optional prefix for log objects inside the bucket."
  default     = ""
}

variable "kms_key_id" {
  type        = string
  description = "KMS key ARN or ID for log file encryption."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the trail."
  default     = {}
}

variable "enable_cloudwatch_logs" {
  type        = bool
  description = "Deliver management events to CloudWatch Logs (additional cost)."
  default     = false
}

variable "attach_cloudwatch_logs_via_delegated_lambda" {
  type        = bool
  description = "When true (and enable_cloudwatch_logs), a Lambda in the delegated (aws.sec) account calls cloudtrail:UpdateTrail to attach the log group and role. The aws_cloudtrail resource stays on the org provider and ignores CWL fields to avoid cross-account API errors and drift."
  default     = true
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "CloudWatch Logs group name for CloudTrail."
  default     = ""
}

variable "cloudwatch_log_group_retention_days" {
  type        = number
  description = "CloudWatch log group retention in days for CloudTrail."
  default     = 90
}

variable "cloudwatch_log_group_deletion_protection_enabled" {
  type        = bool
  description = "Deletion protection on the CloudTrail CloudWatch log group (see aws_cloudwatch_log_group deletion_protection_enabled)."
  default     = true
}

variable "event_selectors" {
  type        = any
  description = "Optional list of event_selector maps (read_write_type, include_management_events, data_resources). Null uses default management events only."
  default     = null
}

variable "sns_topic_arn" {
  type        = string
  description = "Optional SNS topic ARN for log file delivery notifications."
  default     = null
  nullable    = true
}

variable "organization_management_account_id" {
  type        = string
  description = "AWS Organizations management account ID (12 digits). Required when enable_cloudwatch_logs is true; used in the delegated-account CloudWatch Logs role policy."
  default     = ""
}

variable "organization_id" {
  type        = string
  description = "Organization ID (o-xxxxxxxxxx). Required when enable_cloudwatch_logs is true; used for org-trail log stream ARNs in the delegated-account role policy."
  default     = ""
}

