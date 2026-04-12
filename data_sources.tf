data "aws_caller_identity" "sec" {}

data "aws_caller_identity" "log" {
  provider = aws.log
}

data "aws_region" "log" {
  provider = aws.log
}

data "aws_organizations_organization" "this" {
  count = local.cloudtrail_enable
}
