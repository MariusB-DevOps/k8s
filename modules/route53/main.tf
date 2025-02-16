resource "aws_route53_record" "jenkins" {
  zone_id = var.route53_zone_id  # Replace with your Route 53 hosted zone ID
  name    = var.jenkins_ingress_host
  type    = "A"

  alias {
    name                   = var.ingress_controller_public_dns  # Replace with the public DNS of your ingress controller
    zone_id                = var.ingress_controller_zone_id     # Replace with the hosted zone ID of the ingress controller
    evaluate_target_health = false
  }
}
