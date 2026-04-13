locals {
  attach_cloudwatch_logs_via_lambda = var.enable_cloudwatch_logs && var.attach_cloudwatch_logs_via_delegated_lambda

  # Not in use
  want_log_group_arn = local.attach_cloudwatch_logs_via_lambda ? "${aws_cloudwatch_log_group.trail[0].arn}:*" : ""
  want_role_arn      = local.attach_cloudwatch_logs_via_lambda ? aws_iam_role.cloudtrail_cwl[0].arn : ""
  have_log_group_arn = local.attach_cloudwatch_logs_via_lambda ? aws_cloudtrail.this.cloud_watch_logs_group_arn : ""
  have_role_arn      = local.attach_cloudwatch_logs_via_lambda ? aws_cloudtrail.this.cloud_watch_logs_role_arn : ""
  trail_cwl_needs_update_trail = local.attach_cloudwatch_logs_via_lambda && (
    local.have_log_group_arn != local.want_log_group_arn ||
    local.have_role_arn != local.want_role_arn
  )
}

module "trail_cwl_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.7.0"

  count = local.attach_cloudwatch_logs_via_lambda ? 1 : 0

  providers = {
    aws = aws.sec
  }

  function_name = substr("trail-cloudwatch-attach-${var.trail_name}", 0, 64)
  description   = "UpdateTrail CloudWatch Logs attachment for org trail ${var.trail_name}"
  handler       = "index.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60

  maximum_retry_attempts = 0

  source_path = "${path.module}/lambda/trail-cloudwatch-attach/"

  attach_policy_statements = true
  policy_statements = {
    update_org_trail = {
      effect    = "Allow"
      actions   = ["cloudtrail:UpdateTrail"]
      resources = [aws_cloudtrail.this.arn]
    }
    pass_role_cloudtrail = {
      effect    = "Allow"
      actions   = ["iam:PassRole"]
      resources = [aws_iam_role.cloudtrail_cwl[0].arn]
      condition = [{
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = ["cloudtrail.amazonaws.com"]
      }]
    }
  }

  ignore_source_code_hash      = false
  trigger_on_package_timestamp = false

  tags = var.tags
}

resource "terraform_data" "trail_cwl_reinvoke" {
  count = local.attach_cloudwatch_logs_via_lambda ? 1 : 0

  triggers_replace = {
    trail_arn     = aws_cloudtrail.this.arn
    log_group_arn = "${aws_cloudwatch_log_group.trail[0].arn}:*"
    role_arn      = aws_iam_role.cloudtrail_cwl[0].arn
    lambda_code   = module.trail_cwl_lambda[0].lambda_function_source_code_hash
  }
}

resource "aws_lambda_invocation" "trail_cloudwatch_logs" {
  count    = local.attach_cloudwatch_logs_via_lambda ? 1 : 0
  provider = aws.sec

  function_name = module.trail_cwl_lambda[0].lambda_function_name

  input = jsonencode({
    TrailArn              = aws_cloudtrail.this.arn
    LogGroupArn           = "${aws_cloudwatch_log_group.trail[0].arn}:*"
    CloudWatchLogsRoleArn = aws_iam_role.cloudtrail_cwl[0].arn
  })

  lifecycle {
    replace_triggered_by = [terraform_data.trail_cwl_reinvoke[0]]
  }
}
