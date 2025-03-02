output "eks_connect" {
  value = "aws eks --region eu-west-1 update-kubeconfig --name ${aws_eks_cluster.main.name}"
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

output "argocd_alb_hostname" {
  value = aws_lb.argocd_alb.dns_name
}

output "jenkins_alb_hostname" {
  value = aws_lb.jenkins_alb.dns_name
}

output "argocd_url" {
  value = "https://argocd.k8s.it.com"
}

output "jenkins_url" {
  value = "https://jenkins.k8s.it.com"
}

