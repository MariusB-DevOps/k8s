variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS Hostnames"
  type        = bool
  default     = true
}
