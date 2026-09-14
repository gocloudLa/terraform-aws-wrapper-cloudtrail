variable "description" {
  type        = string
  description = "KMS key description."
}

variable "deletion_window_in_days" {
  type        = number
  description = "Waiting period after scheduled deletion (7-30)."
  default     = 30
}

variable "enable_key_rotation" {
  type        = bool
  description = "Enable automatic annual key rotation."
  default     = true
}

variable "alias_name" {
  type        = string
  description = "KMS alias name (must start with alias/)."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the KMS key."
  default     = {}
}

variable "sec_account_id" {
  type        = string
  description = "AWS Organizations management account ID (for CloudTrail trail ARN conditions in the key policy)."
}

variable "trail_name" {
  type        = string
  description = "CloudTrail trail name (must match the trail resource)."
}

variable "log_account_id" {
  type        = string
  description = "Account ID that owns the CloudTrail S3 log bucket (log provider)."
}

variable "log_region" {
  type        = string
  description = "Region of the S3 log bucket (for kms:ViaService)."
}
