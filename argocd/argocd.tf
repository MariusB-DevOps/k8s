data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "mariusb-tf-state"
    key    = "terraform/state/terraform.tfstate"
    region = "eu-west-1"
  }
}

data "aws_eks_cluster" "main" {
  name = "main-eks-cluster"
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.name
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

resource "kubernetes_secret" "argocd_admin" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
}
#data.terraform_remote_state.infra
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.k8s.it.com"
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }

  set {
    name  = "server.ingress.annotations.kubernetes.io/ingress.class"
    value = "alb"
  }

  set {
    name  = "server.ingress.annotations.alb.ingress.kubernetes.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/load-balancer-name"
    value = data.terraform_remote_state.eks.outputs.argocd_alb_hostname
  }

  set {
    name  = "server.ingress.annotations.alb.ingress.kubernetes.io/certificate-arn"
    value = var.certificate_arn
  }

  set {
    name  = "server.ingress.annotations.alb.ingress.kubernetes.io/target-type"
    value = "ip"
  }
}

