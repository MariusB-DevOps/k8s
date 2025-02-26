variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "iam_user_arn" {
  type    = string
  default = "" # Default value is empty; will be overridden by GitHub secret
}

variable "iam_role_arn" {
  type    = string
  default = "" # Default value is empty; will be overridden by GitHub secret
}

variable "iam_username" {
  type    = string
  default = "" # Default value is empty; will be overridden by GitHub secret
}

variable "assume_role_principal_arn" {
  type    = string
  default = "" # Default value is empty; will be overridden by GitHub secret
}
