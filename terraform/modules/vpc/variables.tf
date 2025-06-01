variable "project_name" {
  type        = string
  description = "Project name used for tagging resources"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, staging, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDRs"
  default     = []
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDRs"
  default     = []
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for subnet placement"
}

variable "create_nat_gateway" {
  type        = bool
  description = "Whether to create a NAT Gateway for private subnets"
  default     = false
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags for all resources"
  default     = {}
}

variable "allowed_cidr_blocks" {
  description = "List of allowed CIDR blocks for ingress rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
