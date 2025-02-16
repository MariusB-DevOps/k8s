output "k8s_public_rt_id" {
  description = "The ID of the VPC"
  value       = aws_route_table.k8s_public_rt.id
}