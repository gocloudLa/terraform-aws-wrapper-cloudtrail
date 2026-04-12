locals {
  prefix_with_slash = (
    length(trim(var.s3_key_prefix, "/")) > 0 ?
    "${trim(var.s3_key_prefix, "/")}/" :
    ""
  )

  has_lifecycle = (
    var.lifecycle_glacier_transition_days != null ||
    var.lifecycle_expiration_days != null
  )
}
