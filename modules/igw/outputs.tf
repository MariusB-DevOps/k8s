output "k8s_igw_id" {
  description = "The ID of the IGW"
  value       = aws_internet_gateway.k8s_igw.id
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.k8s_ngw.id
}
