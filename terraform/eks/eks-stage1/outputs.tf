output "cluster_name" {
  value = module.eks.cluster_name
}

# The following outputs are now handled in Stage 2
# output "cluster_endpoint" {
#   value = data.aws_eks_cluster.cluster.endpoint
# }

# output "cluster_certificate_authority_data" {
#   value = data.aws_eks_cluster.cluster.certificate_authority[0].data
# }
