variable "route53_zone_id" {
  description = "The ID of the Route 53 hosted zone"
  type        = string
}

variable "jenkins_ingress_host" {
  description = "The DNS name for Jenkins"
  type        = string
}

variable "ingress_controller_public_dns" {
  description = "The public DNS of the ingress controller"
  type        = string
}

variable "ingress_controller_zone_id" {
  description = "The hosted zone ID of the ingress controller"
  type        = string
}
