output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = data.aws_s3_bucket.existing.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = data.aws_s3_bucket.existing.arn
}

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = data.aws_s3_bucket.existing.id
}
