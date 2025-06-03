provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# VPC
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  create_nat_gateway   = var.create_nat_gateway
  additional_tags      = var.additional_tags
  allowed_cidr_blocks  = var.allowed_cidr_blocks
}

# Storage (S3)
module "storage" {
  source = "./modules/storage"

  project_name      = var.project_name
  environment       = var.environment
  model_bucket_name = var.model_bucket_name
}

# Database (RDS)
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
  security_group_id    = module.vpc.rds_security_group_id
  subnet_ids           = module.vpc.private_subnet_ids
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  project_name               = var.project_name
  environment                = var.environment
  cluster_name               = var.cluster_name
  cluster_version            = var.cluster_version
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  cluster_security_group_ids = []
  node_instance_type         = var.node_instance_type
  desired_capacity           = var.desired_capacity
  min_size                   = var.min_size
  max_size                   = var.max_size
  ami_type                   = var.ami_type
  capacity_type              = var.capacity_type
  disk_size                  = var.disk_size
  node_labels                = var.node_labels
  node_taints                = var.node_taints
  update_max_unavailable     = var.update_max_unavailable
  enabled_cluster_log_types  = var.enabled_cluster_log_types
  endpoint_private_access    = var.endpoint_private_access
  endpoint_public_access     = var.endpoint_public_access
  additional_node_groups     = var.additional_node_groups
  additional_tags            = var.additional_tags
}

# EKS Authentication
data "aws_eks_cluster_auth" "auth" {
  name = module.eks.cluster_name
}

# Update kubeconfig
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
  }

  triggers = {
    cluster_name = module.eks.cluster_name
  }

  depends_on = [module.eks]
}

# Kubernetes Provider
provider "kubernetes" {
  alias                  = "eks"
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.auth.token
}

# Helm provider 
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.auth.token
  }
}

# Ingress-nginx
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.10.0"

  create_namespace = true
  values           = []

  depends_on = [null_resource.update_kubeconfig]
}

data "kubernetes_service" "ingress_nginx" {
  provider = kubernetes.eks

  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.ingress_nginx]
}

# ECR Repository
resource "aws_ecr_repository" "diabetes_ml" {
  name = var.ecr_repository_name

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = {
    Name        = "diabetes-ml"
    Environment = var.environment
  }
}

# Kubernetes Secrets
resource "kubernetes_secret" "app" {
  provider   = kubernetes.eks
  depends_on = [null_resource.update_kubeconfig]

  metadata {
    name = "diabetes-ml-secret"
  }

  data = {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    DB_HOST               = module.database.db_address
    DB_PORT               = tostring(module.database.db_port)
    DB_NAME               = var.db_name
    DB_USER               = var.db_username
    DB_PASSWORD           = var.db_password
  }

  type = "Opaque"
}

# ConfigMap
resource "kubernetes_config_map" "app" {
  provider   = kubernetes.eks
  depends_on = [null_resource.update_kubeconfig]

  metadata {
    name = "diabetes-ml-config"
  }

  data = {
    LOG_LEVEL    = "INFO"
    MODEL_PATH   = "/app/tf_model.h5"
    SCALER_PATH  = "/app/scaler.pkl"
    S3_BUCKET    = var.model_bucket_name
    MODEL_BUCKET = var.model_bucket_name
    AWS_REGION   = var.aws_region
  }
}

# Docker Build and Push to ECR
resource "null_resource" "docker_push" {
  count = fileexists("${path.module}/../Dockerfile") ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      Write-Host "Building Docker image..."
      docker build -t diabetes-ml . ;

      if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build Docker image"
        exit 1
      }

      Write-Host "Tagging image..."
      docker tag diabetes-ml:latest ${aws_ecr_repository.diabetes_ml.repository_url}:latest ;

      Write-Host "Logging into ECR..."
      Invoke-Expression -Command (Get-ECRLoginCommand).Command

      if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to login to ECR"
        exit 1
      }

      Write-Host "Pushing image..."
      docker push ${aws_ecr_repository.diabetes_ml.repository_url}:latest ;

      if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to push Docker image"
        exit 1
      }

      Write-Host "Docker image successfully pushed to ECR"
    EOT

    interpreter = ["PowerShell", "-Command"]
    working_dir = "${path.module}/.."
  }

  triggers = {
    dockerfile_hash = filemd5("${path.module}/../Dockerfile")
    image_tag       = "latest"
  }

  depends_on = [
    aws_ecr_repository.diabetes_ml,
    null_resource.update_kubeconfig
  ]
}


# Helm Deployment
resource "null_resource" "helm_deploy" {
  count = fileexists("${path.module}/../helm/values.dev.yaml") ? 1 : 0

  triggers = {
    cluster_name = module.eks.cluster_name
    docker_image = null_resource.docker_push[0].id
  }

  provisioner "local-exec" {
    command = <<EOT
      Write-Host "Updating kubeconfig..."
      aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}

      if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to update kubeconfig"
        exit 1
      }

      helm upgrade --install diabetes-ml ./helm -f ./helm/values.dev.yaml --set image.repository=${aws_ecr_repository.diabetes_ml.repository_url} --set image.tag=latest --wait --timeout=10m

      if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy application with Helm"
        exit 1
      }

      Write-Host "Application successfully deployed"
    EOT

    working_dir = "${path.module}/.."
    interpreter = ["PowerShell", "-Command"]
  }

  depends_on = [
    null_resource.update_kubeconfig,
    null_resource.docker_push
  ]
}
