resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.enable_sse_kms_default ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_organization" {
  count = var.enable_bucket_policy ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this.arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.cloudtrail_trail_arn_pattern]
    }
    dynamic "condition" {
      for_each = var.enforce_s3_source_org_id_condition && trimspace(var.organization_id) != "" ? [trimspace(var.organization_id)] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceOrgID"
        values   = [condition.value]
      }
    }
  }

  # Covers management account, organization ID prefix (o-xxxx), and member account IDs under AWSLogs/.
  # See https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.this.arn}/${local.prefix_with_slash}AWSLogs/*"
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [var.cloudtrail_trail_arn_pattern]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    dynamic "condition" {
      for_each = var.enforce_s3_source_org_id_condition && trimspace(var.organization_id) != "" ? [trimspace(var.organization_id)] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceOrgID"
        values   = [condition.value]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_bucket_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.cloudtrail_organization[0].json

  depends_on = [
    aws_s3_bucket_public_access_block.this,
  ]
}

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_server_access_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.access_logs_target_bucket
  target_prefix = var.access_logs_target_prefix

  lifecycle {
    precondition {
      condition     = var.access_logs_target_bucket != ""
      error_message = "access_logs_target_bucket must be set when enable_server_access_logging is true."
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.has_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id     = "cloudtrail-logs-lifecycle"
    status = "Enabled"
    filter {}

    dynamic "transition" {
      for_each = var.lifecycle_glacier_transition_days != null ? [1] : []
      content {
        days          = var.lifecycle_glacier_transition_days
        storage_class = "GLACIER"
      }
    }

    dynamic "expiration" {
      for_each = var.lifecycle_expiration_days != null ? [1] : []
      content {
        days = var.lifecycle_expiration_days
      }
    }
  }
}
