variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "k8s-key"
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
