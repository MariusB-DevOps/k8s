variable "allowed_cidr" {
  description = "Allowed CIDR blocks for security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
