output "eks_connect" {
  value = "aws eks --region eu-west-1 update-kubeconfig --name ${aws_eks_cluster.main.name}"
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

