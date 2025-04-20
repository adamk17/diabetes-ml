aws_region         = "eu-central-1"
environment        = "dev"
project_name       = "diabetes-ml"

model_bucket_name  = "your-bucket-name"
aws_access_key_id     = "your-access-key-id"
aws_secret_access_key = "your-secret-access-key"

db_identifier = "your-db-identifier"
db_instance_class  = "db.t4g.micro"
db_allocated_storage = 10
db_name            = "your-db-name"
db_username        = "your-db-user"
db_password        = "your-db-password" 

allowed_cidr_blocks = ["0.0.0.0/0"] # Should be your IP

key_name           = "your-key" # You need to create it in AWS (EC2 → Key Pairs)
pem_base_path      = "C:/Users/USER/.ssh" # Path for your key
instance_type      = "t3.micro"