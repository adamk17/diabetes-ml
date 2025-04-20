variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "diabetes-ml"
}

# S3
variable "model_bucket_name" {
  description = "Name of the S3 bucket for model artifacts"
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS access key for S3 access"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key for S3 access"
  type        = string
  sensitive   = true
}


# RDS
variable "db_identifier" {
  description = "Identifier for RDS instance"
  type        = string
  default     = "diabetes-ml-db"
}

variable "db_instance_class" {
  description = "Class of RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Storage allocated to RDS (in GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "diabetes_db"
}

variable "db_username" {
  description = "Master DB username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to RDS and SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change for production!
}

# EC2
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of your AWS key pair (for SSH access to EC2)"
  type        = string
}

variable "pem_base_path" {
  description = "Base path to the .pem key (e.g., C:/Users/adamk/.ssh)"
  type        = string
}