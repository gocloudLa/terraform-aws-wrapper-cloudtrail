variable "bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for CloudTrail logs."
}

variable "force_destroy" {
  type        = bool
  description = "Allow bucket destruction when non-empty (required for terraform destroy if logs exist)."
  default     = false
}

variable "enable_versioning" {
  type        = bool
  description = "Enable S3 versioning on the log bucket."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the bucket."
  default     = {}
}

variable "s3_key_prefix" {
  type        = string
  description = "S3 key prefix for CloudTrail (must match trail configuration). Empty string means no extra prefix segment before AWSLogs/."
  default     = ""
}

variable "organization_id" {
  type        = string
  description = "Organizations ID (o-xxxxxxxxxx), used when enforce_s3_source_org_id_condition is true."
  default     = ""
}

variable "enforce_s3_source_org_id_condition" {
  type        = bool
  description = "If true and organization_id is set, add aws:SourceOrgID to the bucket policy (verify CloudTrail sets this in your environment before enabling)."
  default     = false
}

variable "enable_bucket_policy" {
  type        = bool
  description = "Attach the CloudTrail organization trail bucket policy (recommended)."
  default     = true
}

variable "cloudtrail_trail_arn_pattern" {
  type        = string
  description = "ArnLike pattern for aws:SourceArn (e.g. arn:aws:cloudtrail:*:MGMT:trail/name for multi-Region trails)."
}

variable "kms_key_arn" {
  type        = string
  description = "KMS CMK ARN for default bucket encryption (SSE-KMS). Key policy must allow the logs account S3 principal."
  default     = ""
}

variable "enable_sse_kms_default" {
  type        = bool
  description = "Enable default SSE-KMS on the bucket using kms_key_arn."
  default     = true
}

variable "enable_server_access_logging" {
  type        = bool
  description = "Enable S3 server access logging for this bucket."
  default     = false
}

variable "access_logs_target_bucket" {
  type        = string
  description = "Target bucket for S3 access logs (required when enable_server_access_logging is true)."
  default     = ""
}

variable "access_logs_target_prefix" {
  type        = string
  description = "Object key prefix for S3 access log objects."
  default     = ""
}

variable "lifecycle_glacier_transition_days" {
  type        = number
  description = "Transition current objects to GLACIER after N days (omit/null to skip)."
  default     = null
}

variable "lifecycle_expiration_days" {
  type        = number
  description = "Expire current objects after N days (omit/null to skip)."
  default     = null
}
