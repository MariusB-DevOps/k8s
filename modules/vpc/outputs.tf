output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.k8s_vpc.id
}