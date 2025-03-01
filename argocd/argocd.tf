data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "mariusb-tf-state"
    key    = "terraform/state/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
  token                  = data.aws_eks_cluster_auth.main.token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority)
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.eks_cluster_endpoint
    token                  = data.aws_eks_cluster_auth.main.token
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.eks_cluster_certificate_authority)
  }
}

data "aws_eks_cluster_auth" "main" {
  name = data.terraform_remote_state.eks.outputs.eks_cluster_name
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.5.2"

  namespace = "argocd"

  create_namespace = true
  force_update     = true  # Forces update if the chart has changes
  atomic           = true  # Ensures safe rollback if update fails
  cleanup_on_fail  = true  # Deletes failed installs automatically
  recreate_pods    = false # Avoids pod restarts if unnecessary

  # Helm annotations to prevent Terraform from breaking on existing installations
  lifecycle {
    ignore_changes = [version]
  }

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "alb"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = var.certificate_arn
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-backend-protocol"
    value = "HTTPS"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-ports"
    value = "443"
  }
}

output "argocd_alb_hostname" {
  value = data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname
}


data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }
}

resource "aws_route53_record" "argocd_dns" {
  zone_id = var.hosted_zone_id
  name    = "argocd.k8s.it.com"
  type    = "A"

  alias {
    name                   = data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.kubernetes_service.argocd_server.metadata[0].uid
    evaluate_target_health = true
  }
}

