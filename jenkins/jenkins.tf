provider "aws" {
  region = "eu-west-1"
}

# Request an ACM Certificate
resource "aws_acm_certificate" "jenkins_cert" {
  domain_name       = "jenkins.k8s.it.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Retrieve Route 53 Hosted Zone
data "aws_route53_zone" "k8s" {
  name = "k8s.it.com"
}

# Create DNS validation record
resource "aws_route53_record" "jenkins_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.jenkins_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.k8s.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Validate ACM Certificate
resource "aws_acm_certificate_validation" "jenkins_cert" {
  certificate_arn         = aws_acm_certificate.jenkins_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.jenkins_cert_validation : record.fqdn]
}

# Attach Certificate to Load Balancer
resource "aws_lb_listener" "jenkins_listener" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:loadbalancer/app/your-alb/your-id"
  port              = 8443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.jenkins_cert.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = "arn:aws:elasticloadbalancing:eu-west-1:123456789012:targetgroup/jenkins-tg/your-id"
  }
}

# Route 53 DNS Record for Jenkins
resource "aws_route53_record" "jenkins_dns" {
  zone_id = data.aws_route53_zone.k8s.zone_id
  name    = "jenkins.k8s.it.com"
  type    = "CNAME"
  ttl     = 300
  records = ["your-alb-dns-name"]
}

# Deploy Jenkins using ArgoCD
resource "kubernetes_manifest" "jenkins_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "jenkins"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://charts.jenkins.io"
        targetRevision = "3.9.3"
        chart          = "jenkins"
        helm = {
          values = <<-EOT
            controller:
              serviceType: NodePort
              ingress:
                enabled: true
                annotations:
                  kubernetes.io/ingress.class: alb
                  alb.ingress.kubernetes.io/scheme: internet-facing
                  alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 8443}]'
                hosts:
                  - "jenkins.k8s.it.com"
          EOT
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "jenkins"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}

