aws_region   = "eu-central-1"
environment  = "dev"
project_name = "diabetes-ml"

# S3
model_bucket_name     = "your-bucket-name"
aws_access_key_id     = "your-access-key-id"
aws_secret_access_key = "your-secret-access-key"

# RDS
db_identifier        = "your-db-identifier"
db_instance_class    = "db.t4g.micro"
db_allocated_storage = 10
db_name              = "your-db-name"
db_username          = "your-db-user"
db_password          = "your-db-password"

allowed_cidr_blocks = ["0.0.0.0/0"] # Should be your IP

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones   = ["eu-central-1a", "eu-central-1b"]
create_nat_gateway   = true

additional_tags = {}

# EKS
cluster_name    = "your-cluster-name"
cluster_version = "1.29"

node_instance_type = "t3.medium"
desired_capacity   = 2
min_size           = 1
max_size           = 3
ami_type           = "AL2_x86_64"
capacity_type      = "ON_DEMAND"
disk_size          = 20

node_labels = {
  role = "ml-api"
}

node_taints = []

update_max_unavailable = 1

enabled_cluster_log_types = ["api", "audit", "authenticator"]

endpoint_private_access = false
endpoint_public_access  = true

additional_node_groups = []
