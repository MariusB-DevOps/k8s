data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "mariusb-tf-state"
    key    = "terraform/state/terraform.tfstate"
    region = "eu-west-1"
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"

  namespace        = "jenkins"
  create_namespace = true
  force_update  = true   # Forces update if the chart has changes
  atomic        = true   # Ensures safe rollback if update fails
  cleanup_on_fail = true # Deletes failed installs automatically
  recreate_pods = false  # Avoids pod restarts if unnecessary

  lifecycle {
    ignore_changes = [version]
  }

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

data "kubernetes_service" "jenkins_service" {
  metadata {
    name      = "jenkins"
    namespace = helm_release.jenkins.namespace
  }
}

resource "aws_route53_record" "jenkins_dns" {
  zone_id = var.hosted_zone_id
  name    = "jenkins.k8s.it.com"
  type    = "A"

  alias {
    name                   = data.kubernetes_service.jenkins_service.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = var.hosted_zone_id
    evaluate_target_health = false
  }
}


