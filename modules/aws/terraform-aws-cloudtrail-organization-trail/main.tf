resource "aws_cloudwatch_log_group" "trail" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name                        = var.cloudwatch_log_group_name
  retention_in_days           = var.cloudwatch_log_group_retention_days
  deletion_protection_enabled = var.cloudwatch_log_group_deletion_protection_enabled

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.cloudwatch_log_group_name != ""
      error_message = "cloudwatch_log_group_name must be set when enable_cloudwatch_logs is true."
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_cwl_assume" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "cloudtrail_cwl" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.trail[0].arn}:*"]
  }
}

resource "aws_iam_role" "cloudtrail_cwl" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name               = local.cloudwatch_role_name
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_cwl_assume[0].json

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_cwl" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name   = "cloudtrail-cwl"
  role   = aws_iam_role.cloudtrail_cwl[0].id
  policy = data.aws_iam_policy_document.cloudtrail_cwl[0].json
}

resource "aws_cloudtrail" "this" {
  name = var.trail_name
  # Organization trail: create from the organization management account (sec provider).
  is_organization_trail = true

  s3_bucket_name = var.s3_bucket_name
  s3_key_prefix  = var.s3_key_prefix

  kms_key_id = var.kms_key_id

  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  enable_logging                = true

  sns_topic_name = var.sns_topic_arn

  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.trail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_cwl[0].arn : null

  dynamic "event_selector" {
    for_each = local.event_selectors_resolved
    content {
      read_write_type           = lookup(event_selector.value, "read_write_type", "All")
      include_management_events = lookup(event_selector.value, "include_management_events", true)

      dynamic "data_resource" {
        for_each = coalesce(try(event_selector.value.data_resources, null), [])
        content {
          type   = data_resource.value.type
          values = data_resource.values
        }
      }
    }
  }

  tags = var.tags
}
