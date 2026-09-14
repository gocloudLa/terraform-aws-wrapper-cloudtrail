output "bucket_id" {
  description = "S3 bucket name (id)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.this.arn
}

output "bucket_policy_id" {
  description = "S3 bucket policy ID when enable_bucket_policy is true."
  value       = try(aws_s3_bucket_policy.cloudtrail[0].id, null)
}
