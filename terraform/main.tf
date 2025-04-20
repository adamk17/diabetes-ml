provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# Template file for user_data
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.tpl")

  vars = {
    aws_access_key_id     = var.aws_access_key_id
    aws_secret_access_key = var.aws_secret_access_key
    aws_region            = var.aws_region
    model_bucket          = module.storage.bucket_name
    db_host               = module.database.db_address
    db_port               = module.database.db_port
    db_name               = var.db_name
    db_user               = var.db_username
    db_password           = var.db_password
  }
}


# Storage module (S3)
module "storage" {
  source = "./modules/storage"

  project_name      = var.project_name
  environment       = var.environment
  model_bucket_name = var.model_bucket_name
}

# Compute module (EC2 and connected)
module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  environment         = var.environment
  instance_type       = var.instance_type
  key_name            = var.key_name
  allowed_cidr_blocks = var.allowed_cidr_blocks
  user_data           = data.template_file.user_data.rendered
  s3_bucket_arn       = module.storage.bucket_arn
}

# Database module
module "database" {
  source = "./modules/database"

  project_name         = var.project_name
  environment          = var.environment
  db_identifier        = var.db_identifier
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  security_group_id    = module.compute.security_group_id
}

# Uploading app code 
resource "null_resource" "upload_app_code" {
  depends_on = [module.compute]

  provisioner "local-exec" {
    command = <<EOT
      Start-Sleep -Seconds 60
      ssh -i "${var.pem_base_path}/${var.key_name}.pem" -o StrictHostKeyChecking=no ubuntu@${module.compute.ec2_public_ip} "sudo mkdir -p /opt/diabetes-ml && sudo chown -R ubuntu:ubuntu /opt/diabetes-ml"
      scp -i "${var.pem_base_path}/${var.key_name}.pem" -o StrictHostKeyChecking=no -r ../api ubuntu@${module.compute.ec2_public_ip}:/opt/diabetes-ml/
      scp -i "${var.pem_base_path}/${var.key_name}.pem" -o StrictHostKeyChecking=no ../Dockerfile ../requirements.txt ubuntu@${module.compute.ec2_public_ip}:/opt/diabetes-ml/
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
}



