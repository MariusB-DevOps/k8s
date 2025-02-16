output "public_nic_ids" {
  description = "The IDs of the public network interfaces"
  value       = [for nic in aws_network_interface.public : nic.id]
}

output "private_nic_ids" {
  description = "The IDs of the private network interfaces"
  value       = [for nic in aws_network_interface.private : nic.id]
}
