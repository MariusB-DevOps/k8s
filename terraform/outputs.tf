output "eks_connect" {
  value = "aws eks --region eu-west-1 update-kubeconfig --name ${aws_eks_cluster.main.name}"
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output "argocd_lb_dns_name" {
  value = aws_lb.argocd_lb.dns_name
}

output "argocd_lb_zone_id" {
  value = aws_lb.argocd_lb.zone_id
}

