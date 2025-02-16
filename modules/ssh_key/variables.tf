variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "k8s-key"
}

variable "public_key_content" {
  description = "The public key content"
  type        = string
}
