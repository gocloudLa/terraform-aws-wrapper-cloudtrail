/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

# variable "metadata" {
#   type = any
# }

/*----------------------------------------------------------------------*/
/* CloudTrail | Variable Definition                                     */
/*----------------------------------------------------------------------*/
variable "cloudtrail_parameters" {
  type        = any
  description = "CloudTrail parameteres to configure the wrapper module"
  default     = {}
}

variable "cloudtrail_defaults" {
  type        = any
  description = "CloudTrail default parameteres for the wrapper module"
  default     = {}
}
