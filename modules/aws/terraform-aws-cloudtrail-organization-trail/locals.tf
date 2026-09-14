locals {
  # IAM role name max 64; trail names from this module are typically safe (letters, digits, hyphen).
  cloudwatch_role_name = substr("cloudtrail-cwl-${var.trail_name}", 0, 64)

  default_event_selectors = [
    {
      read_write_type           = "All"
      include_management_events = true
      data_resources            = []
    },
  ]

  event_selectors_resolved = var.event_selectors != null ? var.event_selectors : local.default_event_selectors
}
