output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster CA certificate data"
  value       = module.eks.cluster_certificate_authority_data
}

output "node_group_arns" {
  description = "ARNs of the EKS node groups"
  value       = module.eks.eks_managed_node_groups
}

