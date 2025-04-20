output "ec2_public_ip" {
  description = "Public IP of the EC2 instance running the model API"
  value       = module.compute.ec2_public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.compute.ec2_public_dns
}

output "rds_endpoint" {
  description = "Endpoint address of the RDS PostgreSQL instance"
  value       = module.database.db_endpoint
}

output "rds_address" {
  description = "Hostname of the RDS PostgreSQL instance"
  value       = module.database.db_address
}

output "s3_bucket_url" {
  description = "S3 bucket URL for model artifacts"
  value       = "https://${module.storage.bucket_name}.s3.${var.aws_region}.amazonaws.com"
}

output "connection_string" {
  description = "Connection string for the API (HTTP endpoint)"
  value       = "http://${module.compute.ec2_public_dns}"
}