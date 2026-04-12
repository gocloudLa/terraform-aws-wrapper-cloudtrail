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
Uses `aws.org` (organization trail), `aws.sec` (delegated account for CloudWatch Logs prerequisites when enabled), `aws.log` (S3 bucket), and `aws.kms` (CMK).

**Organization trail and Terraform / OpenTofu**

For an *organization* trail, AWS still encodes the **management (root) account** in the trail’s ARN, even when a **delegated administrator** creates or updates it. The API calls may run with delegated credentials, but the resource identity AWS returns is not “the delegated account’s trail ARN”.

```text
# Example only (not real accounts):
#   delegated account ID   = 999988887777  # provider / STS identity
#   management account ID  = 111122223333  # Organizations root

Trail ARN from DescribeTrail / resource output:
arn:aws:cloudtrail:us-east-2:111122223333:trail/my-org-trail
                                ^^^^^^^^^^^^^
                                always the management account for org trails
```

If you attach `aws_cloudtrail` to the **delegated** provider, Terraform / OpenTofu is managing that resource **in the context of the delegated account** (credentials, default assumptions, and often how operators read `provider = aws.sec`). The **returned `arn` attribute does not match that context**: it still shows `111122223333`, not `999988887777`. That mismatch is confusing for state, refresh, and any logic (policies, outputs, or sibling modules) that assumes “trail ARN account ID == provider account ID”.

```hcl
# Misleading pairing: API caller is delegated, ARN is management.
resource "aws_cloudtrail" "this" {
  provider = aws.sec # STS: 999988887777
  name     = "my-org-trail"
  # ...
}

# Typical output after apply:
# aws_cloudtrail.this.arn
# => "arn:aws:cloudtrail:us-east-2:111122223333:trail/my-org-trail"
#    Account in ARN (1111...) != account implied by provider (9999...)
```

So the problem is not “AWS is wrong”—it is **consistent for org trails**—but **Terraform ties one resource to one provider account**, while **the canonical trail ARN always carries the management ID**. Keeping **`aws_cloudtrail` on `aws.org`** lines up provider account, API identity for the primary trail lifecycle, and the ARN’s account field, which avoids that inconsistency. CloudWatch Logs in another account remains a separate concern (see below).

**CloudWatch Logs: two patterns**

* **Log group in the management account** — Same account as the trail resource. Terraform can set `CloudWatchLogsLogGroupArn` and `CloudWatchLogsRoleArn` on `aws_cloudtrail` in one flow: caller account, log group, and role align with AWS rules, and there is no split API identity.

* **Log group in a designated account (e.g. security / delegated admin)** — AWS requires the CloudWatch log group used for delivery to exist in the *caller* account when you configure that integration via `CreateTrail` / `UpdateTrail`, and the IAM role CloudTrail assumes for Logs must work with that log group. The management-account provider cannot successfully apply those attributes while pointing at resources in another account (e.g. cross-account PassRole or “log group must be owned by the current account”). The supported operational sequence is: create the trail with Terraform on `aws.org`; create the log group and role in the delegated account (`aws.sec`); then run **`UpdateTrail` using credentials from that delegated account** (for example with the AWS CLI), passing the full trail ARN and the log group and role ARNs in the security account. That second step is not something a single `aws_cloudtrail` block on `aws.org` can do honestly in one apply without hitting those AWS constraints—so it is either done **manually or by separate automation outside the trail resource** that calls the CloudTrail API with the delegated account’s credentials.


### ✨ Features

-  [Multi-provider layout (org / sec / log / kms)](#multi-provider-layout-(org-/-sec-/-log-/-kms)) - Map each provider alias to the right AWS configuration.

-  [Organization trail and bucket policy](#organization-trail-and-bucket-policy) - Multi-Region trail, S3 policy with CloudTrail service principal and ArnLike on SourceArn.

-  [KMS for CloudTrail and bucket encryption](#kms-for-cloudtrail-and-bucket-encryption) - Key policy allows CloudTrail GenerateDataKey, logs-account decrypt, and S3 via kms:ViaService.



### 🔗 External Modules
| Name | Version |
|------|------:|
| <a href="https://github.com/terraform-aws-modules/terraform-aws-lambda" target="_blank">terraform-aws-modules/lambda/aws</a> | 8.7.0 |



## 🚀 Quick Start
```hcl
module "cloudtrail" {
  source = "gocloudLa/wrapper-cloudtrail/aws"

  providers = {
    aws.org = aws.org # management — organization trail
    aws.sec = aws.sec # delegated admin — CloudWatch Logs (same as aws.org if single account)
    aws.log = aws.log # log archive — S3 bucket
    aws.kms = aws.kms # CMK account
  }

  metadata = local.metadata

  cloudtrail_parameters = {
    enable = true

    log_bucket = {
      force_destroy = false
    }

    kms = {
      deletion_window_in_days = 30
      enable_key_rotation     = true
    }

    trail = {
      enable_cloudwatch_logs = false
    }
  }
}
```


## 🔧 Additional Features Usage

### Multi-provider layout (org / sec / log / kms)
`aws.org` runs the organization trail. With CloudWatch Logs enabled, the log group and IAM role are created in `aws.sec` (delegated admin pattern); pass the same provider as `aws.org` for a single-account lab.
`aws.log` owns the S3 bucket; `aws.kms` owns the CMK.


<details><summary>Same account</summary>

```hcl
providers = { aws.org = aws, aws.sec = aws, aws.log = aws, aws.kms = aws }
```


</details>


### Organization trail and bucket policy
Bucket policy follows AWS guidance for CloudTrail delivery under the optional key prefix and `AWSLogs/*`.
Optional `aws:SourceOrgID` can be enabled via `log_bucket.enforce_s3_source_org_id` when validated in your org.


<details><summary>Reference</summary>

```text
https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
```


</details>


### KMS for CloudTrail and bucket encryption
Supports the common pattern where the CMK lives in a sec or log-archive account and the bucket uses SSE-KMS with bucket key enabled.


<details><summary>KMS block</summary>

```hcl
kms = { deletion_window_in_days = 30, enable_key_rotation = true }
```


</details>




## 📑 Inputs
| Name                             | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Type   | Default  | Required |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------- | -------- |
| metadata                         | Standard GoCloud metadata (`key.company`, `key.env`, `environment`, optional `common_name` / `common_tags`, `aws_region` in consumers)                                                                                                                                                                                                                                                                                                                                                                              | `any`  | —        | yes      |
| cloudtrail_parameters            | Main input map (`enable`, `trail_name`, `s3_key_prefix`, `tags`, nested `log_bucket`, `kms`, `trail`)                                                                                                                                                                                                                                                                                                                                                                                                               | `any`  | `{}`     | no       |
| cloudtrail_defaults              | Optional defaults (e.g. `tags`); merged with `metadata.common_tags` and `cloudtrail_parameters.tags` on all child resources                                                                                                                                                                                                                                                                                                                                                                                         | `any`  | `{}`     | no       |
| **cloudtrail_parameters.enable** | Create all resources                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | `bool` | `false`  | no       |
| **log_bucket**                   | `bucket_name`, `force_destroy`, `enable_versioning` (default true), `enable_bucket_policy`, `enable_sse_kms_default`, `enforce_s3_source_org_id`, access logging, lifecycle                                                                                                                                                                                                                                                                                                                                         | `map`  | see code | no       |
| **kms**                          | `alias_name`, `description`, `deletion_window_in_days`, `enable_key_rotation`                                                                                                                                                                                                                                                                                                                                                                                                                                       | `map`  | see code | no       |
| **trail**                        | `enable_cloudwatch_logs` (log group + role in `aws.sec`), `attach_cloudwatch_logs_via_delegated_lambda` (default true: Lambda in `aws.sec` calls `UpdateTrail`; set false to attach CWL yourself), `cloudwatch_log_group_name`, `cloudwatch_log_group_retention_days`, `cloudwatch_log_group_deletion_protection_enabled`, `event_selectors`, `sns_topic_arn` (sent as `sns_topic_name` to AWS; name or ARN). Org ID and management account ID for the CWL role policy come from Organizations data in the wrapper. | `map`  | see code | no       |







## ⚠️ Important Notes
- **Management account:** `is_organization_trail = true` must be created from the AWS Organizations management account (or delegated pattern per AWS docs).
- **Organizations:** When `enable = true`, the module reads `aws_organizations_organization` on the default provider.
- **Destroy order:** Terraform usually destroys the trail before the bucket; use `log_bucket.force_destroy = true` if objects remain.
- **Graph:** The trail module takes `s3_bucket_name` and `kms_key_id` from sibling module outputs, so Terraform orders creates/updates without explicit `depends_on`.
- **Event selectors:** Override with `trail.event_selectors` when needed; omit to keep the module default (management events).
- **Destroy protection:** Terraform `lifecycle.prevent_destroy` cannot use variables; use stack policy, IAM, or manual processes to guard production deletes.



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