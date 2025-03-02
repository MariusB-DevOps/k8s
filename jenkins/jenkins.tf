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
    value = "ClusterIP"
  }

  set {
    name  = "controller.ingress.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingress.hosts[0].host"
    value = "jenkins.k8s.it.com"
  }

  set {
    name  = "controller.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "alb"
  }

  set {
    name  = "controller.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
    value = data.terraform_remote_state.alb.outputs.jenkins_alb_hostname
  }

  set {
    name  = "controller.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = var.certificate_arn
  }

  set {
    name  = "controller.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }
}

