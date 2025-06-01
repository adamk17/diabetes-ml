variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "model_bucket_name" {
  description = "Name of an existing S3 bucket for model artifacts"
  type        = string
}
