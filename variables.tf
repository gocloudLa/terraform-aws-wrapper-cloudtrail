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
  description = ""
  default     = {}
}

variable "cloudtrail_defaults" {
  type        = any
  description = ""
  default     = {}
}
