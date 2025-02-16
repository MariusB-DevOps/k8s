#output "public_subnet_id" {
#  description = "The ID of the public subnet"
#  value       = aws_subnet.public_subnet.id
#}

#output "private_subnet_id" {
#  description = "The ID of the private subnet"
#  value       = aws_subnet.private_subnet.id
#}
output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = [for subnet in aws_subnet.private_subnet : subnet.id]
}

