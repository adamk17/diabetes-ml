# S3
output "s3_bucket_url" {
  description = "S3 bucket URL for model artifacts"
  value       = "https://${module.storage.bucket_name}.s3.${var.aws_region}.amazonaws.com"
}

# RDS
output "rds_endpoint" {
  description = "Endpoint address of the RDS PostgreSQL instance"
  value       = module.database.db_endpoint
}

output "rds_address" {
  description = "Hostname of the RDS PostgreSQL instance"
  value       = module.database.db_address
}

# EKS
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_kubeconfig_command" {
  description = "Command to update your kubeconfig for the EKS cluster"
  value       = module.eks.kubeconfig_command
}

output "eks_node_groups" {
  description = "Node group details"
  value       = module.eks.node_groups
}

output "ingress_nginx_service_hostname" {
  description = "Hostname of the ingress-nginx LoadBalancer"
  value       = try(
    data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname,
    null
  )
}

output "ingress_nginx_service_ip" {
  description = "External IP of the ingress-nginx LoadBalancer"
  value       = try(
    data.kubernetes_service.ingress_nginx.status[0].load_balancer[0].ingress[0].ip,
    null
  )
}

# ECR
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.diabetes_ml.repository_url
}
