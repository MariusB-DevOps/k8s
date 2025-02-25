terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  backend "s3" {
    bucket = "mariusb-tf-state"
    key    = "terraform/state/eks-stage2.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "terraform_remote_state" "eks_stage1" {
  backend = "s3"
  config = {
    bucket = "mariusb-tf-state"
    key    = "terraform/state/eks-stage1.tfstate"
    region = "eu-west-1"
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks_stage1.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_stage1.outputs.cluster_certificate_authority_data)
  token                  = var.eks_token
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks_stage1.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks_stage1.outputs.cluster_certificate_authority_data)
    token                  = var.eks_token
  }
}

variable "eks_token" {}

# Add Kubernetes resources or Helm charts here
