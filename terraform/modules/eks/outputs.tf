output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "Name of the EKS cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "Endpoint for the EKS cluster API server"
}

output "cluster_certificate_authority_data" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "Base64 encoded certificate data required to communicate with the cluster"
}

output "cluster_arn" {
  value       = aws_eks_cluster.this.arn
  description = "ARN of the EKS cluster"
}

output "cluster_id" {
  value       = aws_eks_cluster.this.id
  description = "ID of the EKS cluster"
}

output "cluster_version" {
  value       = aws_eks_cluster.this.version
  description = "Kubernetes version of the EKS cluster"
}

output "cluster_security_group_id" {
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  description = "Security Group ID attached to the EKS cluster"
}

output "node_group_role_arn" {
  value       = aws_iam_role.node_role.arn
  description = "ARN of the IAM role for node groups"
}

output "kubeconfig_command" {
  value       = "aws eks update-kubeconfig --region $(terraform output -raw region) --name ${aws_eks_cluster.this.name}"
  description = "Command to update kubeconfig for this EKS cluster"
}

output "node_groups" {
  value = {
    primary = {
      name   = aws_eks_node_group.this.node_group_name
      arn    = aws_eks_node_group.this.arn
      status = aws_eks_node_group.this.status
    }
    additional = [
      for ng in aws_eks_node_group.additional : {
        name   = ng.node_group_name
        arn    = ng.arn
        status = ng.status
      }
    ]
  }
  description = "Details about the node groups in the EKS cluster"
}
