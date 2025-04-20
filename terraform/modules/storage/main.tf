# S3 existing bucket
data "aws_s3_bucket" "existing" {
  bucket = var.model_bucket_name
}
