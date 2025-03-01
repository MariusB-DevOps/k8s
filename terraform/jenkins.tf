resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"

  namespace        = "jenkins"
  create_namespace = true

  set {
    name  = "controller.serviceType"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.serviceAnnotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "alb"
  }

  set {
    name  = "controller.serviceAnnotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = var.certificate_arn
  }

  set {
    name  = "controller.serviceAnnotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "HTTPS"
  }

  set {
    name  = "controller.serviceAnnotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "443"
  }
}

resource "aws_route53_record" "jenkins_dns" {
  zone_id = var.hosted_zone_id
  name    = "jenkins.k8s.it.com"
  type    = "A"

  alias {
    name                   = aws_lb.jenkins_lb.dns_name
    zone_id                = aws_lb.jenkins_lb.zone_id
    evaluate_target_health = false
  }
}

