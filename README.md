# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform CloudTrail Organization Trail Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-cloudtrail/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-cloudtrail.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-cloudtrail.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-cloudtrail/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
Wrapper for an organization-level, multi-Region AWS CloudTrail trail with a dedicated S3 log bucket,
SSE-KMS default encryption, organization bucket policy, optional S3 access logging and lifecycle,
optional CloudWatch Logs, configurable event selectors, optional SNS notifications, and a
customer-managed KMS key whose policy supports CloudTrail and cross-account S3 use.


### ✨ Features

- 🌲 [Organization trail with log bucket and CMK](#organization-trail-with-log-bucket-and-cmk) - Multi-Region organization trail writing to a dedicated S3 bucket encrypted with a customer-managed KMS key.

- 📡 [CloudWatch Logs in the delegated account](#cloudwatch-logs-in-the-delegated-account) - Optional log group and IAM role on `aws.sec`, attached with UpdateTrail from that account.

- 🎯 [Event selectors](#event-selectors) - Replace the default management-events selector when you need data events or a narrower read/write filter.



### 🔗 External Modules
| Name | Version |
|------|------:|
| <a href="https://github.com/terraform-aws-modules/terraform-aws-lambda" target="_blank">terraform-aws-modules/lambda/aws</a> | 8.7.0 |



## 🚀 Quick Start
```hcl
cloudtrail_parameters = {
  enable = true

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
  }

  # -------------------------------------------------------------------------
  # trail — commented lines show wrapper defaults; uncomment to override.
  # -------------------------------------------------------------------------
  trail = {
    # enable_cloudwatch_logs                              = false
    # cloudwatch_log_group_name                           = null
    # cloudwatch_log_group_retention_days                 = 90
    # cloudwatch_log_group_deletion_protection_enabled    = true
    # event_selectors                                     = null
    # sns_topic_arn                                       = null

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
```


## 🔧 Additional Features Usage

### Organization trail with log bucket and CMK
Creates the organization `aws_cloudtrail` on `aws.org`, the log archive bucket on `aws.log`, and the CMK on `aws.kms`.
Set `enable = true` and override nested `log_bucket` / `kms` / `trail` keys only when you need non-defaults.


<details><summary>Enable the organization trail</summary>

```hcl
cloudtrail_parameters = {
  enable = true

  log_bucket = {
    force_destroy = true # Default: false
  }

  kms = {
    deletion_window_in_days = 7     # Default: 30
    enable_key_rotation     = false # Default: true
  }
}
```


</details>


### CloudWatch Logs in the delegated account
When `trail.enable_cloudwatch_logs` is true, the module creates the log group and delivery role on `aws.sec`.
Cross-account attach uses a Lambda that calls `cloudtrail:UpdateTrail`; the org-side `aws_cloudtrail` does not set CWL attributes.
Use the same provider for `aws.org` and `aws.sec` when the trail and log group live in one account.


<details><summary>Deliver trail events to CloudWatch Logs</summary>

```hcl
cloudtrail_parameters = {
  enable = true

  trail = {
    enable_cloudwatch_logs                           = true  # Default: false
    cloudwatch_log_group_deletion_protection_enabled = false # Default: true
  }
}
```


</details>


### Event selectors
Omit `trail.event_selectors` to keep the module default (all management events). Set a list of selector maps to override `event_selector` blocks on `aws_cloudtrail`.


<details><summary>Management events plus S3 data events</summary>

```hcl
cloudtrail_parameters = {
  enable = true

  trail = {
    event_selectors = [
      {
        read_write_type           = "All"
        include_management_events = true
        data_resources = [
          {
            type   = "AWS::S3::Object"
            values = ["arn:aws:s3:::example-bucket/"]
          },
        ]
      },
    ]
  }
}
```


</details>




## 📑 Inputs
| Name                                                   | Description                                                                                                                                                         | Type     | Default                                                       | Required |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------------------------------------------- | -------- |
| enable                                                 | When `true`, create KMS, bucket, trail, and related resources (`count` gate).                                                                                       | `bool`   | `false`                                                       | no       |
| trail_name                                             | `name` on `aws_cloudtrail` (trail identifier).                                                                                                                      | `string` | `` `{common_name}-org-trail` ``                               | no       |
| s3_key_prefix                                          | `s3_key_prefix` on `aws_cloudtrail`; prefix for log objects under the bucket.                                                                                       | `string` | `"cloudtrail"`                                                | no       |
| kms.description                                        | `description` on `aws_kms_key`.                                                                                                                                     | `string` | `` `KMS key for CloudTrail log encryption ({common_name})` `` | no       |
| kms.deletion_window_in_days                            | `deletion_window_in_days` on `aws_kms_key` (waiting period after schedule delete, 7–30).                                                                            | `number` | `30`                                                          | no       |
| kms.enable_key_rotation                                | `enable_key_rotation` on `aws_kms_key`.                                                                                                                             | `bool`   | `true`                                                        | no       |
| kms.alias_name                                         | `name` on `aws_kms_alias` (must start with `alias/`).                                                                                                               | `string` | `` `alias/{common_name}-cloudtrail` ``                        | no       |
| log_bucket.bucket_name                                 | Globally unique `bucket` name on `aws_s3_bucket`.                                                                                                                   | `string` | `` `{common_name}-cloudtrail-logs-{log_account_id}` ``        | no       |
| log_bucket.force_destroy                               | `force_destroy` on `aws_s3_bucket` (allow delete when bucket has objects).                                                                                          | `bool`   | `false`                                                       | no       |
| log_bucket.enable_versioning                           | S3 bucket versioning (`aws_s3_bucket_versioning`).                                                                                                                  | `bool`   | `true`                                                        | no       |
| log_bucket.enforce_s3_source_org_id                    | If `true` and org ID is known, bucket policy adds `aws:SourceOrgID` condition (validate for your org before enabling).                                              | `bool`   | `false`                                                       | no       |
| log_bucket.enable_bucket_policy                        | Attach module CloudTrail organization trail bucket policy.                                                                                                          | `bool`   | `true`                                                        | no       |
| log_bucket.enable_sse_kms_default                      | Default encryption on the bucket using the module CMK (`aws_s3_bucket_server_side_encryption_configuration`).                                                       | `bool`   | `true`                                                        | no       |
| log_bucket.enable_server_access_logging                | S3 server access logging for this bucket.                                                                                                                           | `bool`   | `false`                                                       | no       |
| log_bucket.access_logs_target_bucket                   | Target bucket for access logs (required if server access logging is enabled).                                                                                       | `string` | `""`                                                          | no       |
| log_bucket.access_logs_target_prefix                   | Key prefix for access log objects.                                                                                                                                  | `string` | `"s3-access-logs/"`                                           | no       |
| log_bucket.lifecycle_glacier_transition_days           | Lifecycle rule: transition current version to `GLACIER` after N days; `null` skips.                                                                                 | `number` | `null`                                                        | no       |
| log_bucket.lifecycle_expiration_days                   | Lifecycle rule: expire current objects after N days; `null` skips.                                                                                                  | `number` | `null`                                                        | no       |
| trail.enable_cloudwatch_logs                           | Turn on CloudWatch Logs delivery (log group and IAM role in `aws.sec`; see module notes).                                                                           | `bool`   | `false`                                                       | no       |
| trail.attach_cloudwatch_logs_via_delegated_lambda      | If `true` with CWL enabled, Lambda in `aws.sec` calls `cloudtrail:UpdateTrail`; org `aws_cloudtrail` ignores CWL attributes.                                        | `bool`   | `true`                                                        | no       |
| trail.cloudwatch_log_group_name                        | `name` on `aws_cloudwatch_log_group` for trail logs.                                                                                                                | `string` | `` `/aws/cloudtrail/{trail_name}` ``                          | no       |
| trail.cloudwatch_log_group_retention_days              | `retention_in_days` on `aws_cloudwatch_log_group`.                                                                                                                  | `number` | `90`                                                          | no       |
| trail.cloudwatch_log_group_deletion_protection_enabled | `deletion_protection_enabled` on `aws_cloudwatch_log_group`.                                                                                                        | `bool`   | `true`                                                        | no       |
| trail.event_selectors                                  | `event_selector` blocks on `aws_cloudtrail` (`read_write_type`, `include_management_events`, `data_resources`); `null` uses module default (all management events). | `any`    | `null`                                                        | no       |
| trail.sns_topic_arn                                    | Passed to `sns_topic_name` on `aws_cloudtrail` (AWS accepts topic name or ARN).                                                                                     | `string` | `null`                                                        | no       |
| tags                                                   | A map of tags to assign to resources.                                                                                                                               | `map`    | `{}`                                                          | no       |







## ⚠️ Important Notes
- **Org trail ARN vs provider (this module):** Organization trail ARNs always use the **management** account ID. Putting `aws_cloudtrail` on a **delegated** provider makes that ARN disagree with the provider account (noisy refresh/drift). **`aws_cloudtrail` stays on `aws.org`.**
- **CloudWatch Logs in `aws.sec`:** Configuring delivery to a log group there requires **`UpdateTrail` with credentials from that account**. The module uses a **Lambda in `aws.sec`**; the org-side trail resource does not apply cross-account CWL in one step. **Same account:** use the same provider for `aws.org` and `aws.sec`, or turn off the delegated Lambda path if you attach CWL yourself.
- **Management account:** `is_organization_trail = true` must be created from the AWS Organizations management account (or delegated pattern per AWS docs).
- **Event selectors:** Override with `trail.event_selectors` when needed; omit to keep the module default (management events).



---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 