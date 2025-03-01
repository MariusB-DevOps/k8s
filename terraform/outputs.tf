output "eks_connect" {
  value = "aws eks --region eu-west-1 update-kubeconfig --name ${aws_eks_cluster.main.name}"
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_certificate_authority" {
  description = "The certificate authority for EKS"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

