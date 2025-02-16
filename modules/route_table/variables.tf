variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "k8s_igw_id"  {
  description = "The ID of the IGW"
  type        = string
}

variable "public_subnet_map" {
  description = "A map of public subnet IDs"
  type        = map(string)
}
