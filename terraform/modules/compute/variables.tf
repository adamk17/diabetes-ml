variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair for SSH access"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to EC2"
  type        = list(string)
}

variable "user_data" {
  description = "User data script for EC2 instance"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for model storage"
  type        = string
}