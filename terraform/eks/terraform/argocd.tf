terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}


provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  token                  = data.aws_eks_cluster_auth.main.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    token                  = data.aws_eks_cluster_auth.main.token
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  }
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

resource "helm_release" "argocd" {
  depends_on = [aws_eks_node_group.main]
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.5.2"

  namespace = "argocd"

  create_namespace = true

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "server.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }
}


data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = helm_release.argocd.namespace
  }
}

resource "null_resource" "get_argocd_password" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command    = <<EOF
      kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    EOF
    on_failure = fail
  }

  provisioner "local-exec" {
    command    = <<EOF
      echo "${self.outputs.stdout}" > argocd_password.txt
    EOF
    on_failure = fail
  }
}

# AWS Secrets Manager Data Sources

data "aws_secretsmanager_secret_version" "repo_url" {
  secret_id = "argocd-repo-url"
}

data "aws_secretsmanager_secret_version" "repo_username" {
  secret_id = "argocd-repo-username"
}

data "aws_secretsmanager_secret_version" "repo_token" {
  secret_id = "argocd-repo-token"
}

locals {
  repo_url              = data.aws_secretsmanager_secret_version.repo_url.secret_string
  repo_username         = data.aws_secretsmanager_secret_version.repo_username.secret_string
  repo_token            = data.aws_secretsmanager_secret_version.repo_token.secret_string
  argocd_admin_password = null_resource.get_argocd_password.provisioners["local-exec"].outputs.stdout
}

resource "null_resource" "argocd_repo_cli" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOF
      argocd login argocd-server.argocd.svc.cluster.local --username admin --password "${local.argocd_admin_password}" --insecure-skip-tls-verify
      argocd repo add "${local.repo_url}" \
        --username "${local.repo_username}" \
        --password "${local.repo_token}" \
        --name "my-github-repo" \
        --insecure-skip-tls-verify
    EOF
  }
}
