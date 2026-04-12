data "aws_region" "cwl" {
  count    = var.enable_cloudwatch_logs ? 1 : 0
  provider = aws.sec
}

resource "aws_cloudwatch_log_group" "trail" {
  count    = var.enable_cloudwatch_logs ? 1 : 0
  provider = aws.sec

  name                        = var.cloudwatch_log_group_name
  retention_in_days           = var.cloudwatch_log_group_retention_days
  deletion_protection_enabled = var.cloudwatch_log_group_deletion_protection_enabled

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.cloudwatch_log_group_name != ""
      error_message = "cloudwatch_log_group_name must be set when enable_cloudwatch_logs is true."
    }
    precondition {
      condition = (
        length(trimspace(var.organization_management_account_id)) > 0 &&
        length(trimspace(var.organization_id)) > 0 &&
        startswith(trimspace(var.organization_id), "o-")
      )
      error_message = "When enable_cloudwatch_logs is true, set organization_management_account_id and organization_id (must start with o-) for the delegated CloudWatch Logs IAM policy."
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

  # Organization trail + log group in delegated account — stream ARNs per AWS / delegated-admin guidance.
  statement {
    sid    = "AWSCloudTrailCreateLogStream20141101"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
    ]
    resources = [
      "${aws_cloudwatch_log_group.trail[0].arn}:log-stream:${trimspace(var.organization_management_account_id)}_CloudTrail_${data.aws_region.cwl[0].id}*",
      "${aws_cloudwatch_log_group.trail[0].arn}:log-stream:${trimspace(var.organization_id)}_*",
    ]
  }

  statement {
    sid    = "AWSCloudTrailPutLogEvents20141101"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.trail[0].arn}:log-stream:${trimspace(var.organization_management_account_id)}_CloudTrail_${data.aws_region.cwl[0].id}*",
      "${aws_cloudwatch_log_group.trail[0].arn}:log-stream:${trimspace(var.organization_id)}_*",
    ]
  }
}

resource "aws_iam_role" "cloudtrail_cwl" {
  count    = var.enable_cloudwatch_logs ? 1 : 0
  # provider = aws.sec

  name               = local.cloudwatch_role_name
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_cwl_assume[0].json

  tags = var.tags
}

resource "aws_iam_policy" "cloudtrail_cwl" {
  count    = var.enable_cloudwatch_logs ? 1 : 0
  # provider = aws.sec

  name        = substr("${local.cloudwatch_role_name}-logs-policy", 0, 128)
  description = "CloudTrail delivery to CloudWatch Logs for trail ${var.trail_name}"
  policy      = data.aws_iam_policy_document.cloudtrail_cwl[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cwl" {
  count    = var.enable_cloudwatch_logs ? 1 : 0
  # provider = aws.sec

  role       = aws_iam_role.cloudtrail_cwl[0].name
  policy_arn = aws_iam_policy.cloudtrail_cwl[0].arn
}

resource "aws_cloudtrail" "this" {
  name = var.trail_name

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
