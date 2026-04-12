module "wrapper_cloudtrail" {
  source = "../../"

  providers = {
    aws     = aws
    aws.log = aws
    aws.kms = aws
  }

  metadata = local.metadata

  cloudtrail_parameters = {
    enable = false

    # -------------------------------------------------------------------------
    # Top-level — only add keys when you need non-defaults (see ../../locals.tf)
    # -------------------------------------------------------------------------
    # trail_name    = null  # default: "${metadata.common_name}-org-trail"
    # s3_key_prefix = "cloudtrail"
    # tags          = {}

    # -------------------------------------------------------------------------
    # log_bucket — commented lines show wrapper defaults; uncomment to override.
    # -------------------------------------------------------------------------
    log_bucket = {
      # bucket_name                       = null
      # enable_versioning                 = true
      # enable_bucket_policy              = true
      # enable_sse_kms_default            = true
      # enforce_s3_source_org_id          = false
      # enable_server_access_logging      = false
      # access_logs_target_bucket         = ""
      # access_logs_target_prefix         = "s3-access-logs/"
      # lifecycle_glacier_transition_days = null
      # lifecycle_expiration_days         = null

      force_destroy = true # Default: false
    }

    # -------------------------------------------------------------------------
    # kms — commented lines show wrapper defaults; uncomment to override.
    # -------------------------------------------------------------------------
    kms = {
      # alias_name              = null
      # description             = null
      # deletion_window_in_days = 30
      # enable_key_rotation     = true

      deletion_window_in_days = 7     # Default: 30
      enable_key_rotation     = false # Default: true
    }

    # -------------------------------------------------------------------------
    # trail — commented lines show wrapper defaults; uncomment to override.
    # -------------------------------------------------------------------------
    trail = {
      # enable_cloudwatch_logs          = false
      # cloudwatch_log_group_name       = null
      # cloudwatch_log_retention_days   = 90
      # event_selectors                 = null
      # sns_topic_arn                   = null
      #
      # event_selectors example (replaces default when set):
      # event_selectors = [
      #   {
      #     read_write_type           = "All"
      #     include_management_events = true
      #     data_resources            = []
      #   },
      # ]
    }
  }

  cloudtrail_defaults = {}
}
