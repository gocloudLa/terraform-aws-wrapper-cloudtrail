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

variable "cloudwatch_log_group_name" {
  type        = string
  description = "CloudWatch Logs group name for CloudTrail."
  default     = ""
}

variable "cloudwatch_log_retention_days" {
  type        = number
  description = "Log retention in days for the CloudTrail log group."
  default     = 90
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

