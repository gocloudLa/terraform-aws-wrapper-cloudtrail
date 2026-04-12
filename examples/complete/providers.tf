provider "aws" {
  region = local.metadata.aws_region
}

# Multi-account: use distinct providers and pass them in main.tf, e.g.
# providers = { aws = aws.sec, aws.log = aws.log, aws.kms = aws.kms }
#
# provider "aws" {
#   alias  = "sec"
#   region = local.metadata.aws_region
#   assume_role { role_arn = "arn:aws:iam::<MGMT_ACCOUNT_ID>:role/TerraformOrgAdmin" }
# }
#
# provider "aws" {
#   alias  = "log"
#   region = local.metadata.aws_region
#   assume_role { role_arn = "arn:aws:iam::<LOG_ACCOUNT_ID>:role/TerraformLogArchive" }
# }
#
# provider "aws" {
#   alias  = "kms"
#   region = local.metadata.aws_region
#   assume_role { role_arn = "arn:aws:iam::<KMS_ACCOUNT_ID>:role/TerraformKms" }
# }
