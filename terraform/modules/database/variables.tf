variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod, etc.)"
  type        = string
}

variable "db_identifier" {
  description = "Identifier for RDS instance"
  type        = string
}

variable "db_instance_class" {
  description = "Class of RDS instance"
  type        = string
}

variable "db_allocated_storage" {
  description = "Storage allocated to RDS (in GB)"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
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

variable "security_group_id" {
  description = "ID of the security group to associate with RDS"
  type        = string
}

variable "publicly_accessible" {
  description = "Whether the RDS instance should be publicly accessible"
  type        = bool
  default     = false
}

