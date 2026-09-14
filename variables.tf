/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

variable "metadata" {
  type = any
}

/*----------------------------------------------------------------------*/
/* CloudTrail | Variable Definition                                     */
/*----------------------------------------------------------------------*/

variable "cloudtrail_parameters" {
  type        = any
  description = "Organization CloudTrail trail, log bucket, and KMS configuration."
  default     = {}
}

variable "cloudtrail_defaults" {
  type        = any
  description = "Default values merged into each entry of cloudtrail_parameters."
  default     = {}
}
