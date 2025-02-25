terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "mariusb-tf-state"
    key    = "terraform/state/eks-stage1.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "mariusb-eks"
  cluster_version = "1.32"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      desired_capacity = 2
      min_size         = 1
      max_size         = 3

      instance_types = ["t3.medium"]
    }
  }

  # Allow access to the EKS API server from your IP
  cluster_endpoint_public_access_cidrs = ["86.120.230.117/32"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "mariusb-eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}
