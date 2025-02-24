terraform {
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "mariusb-tf-state"
    key            = "terraform/state/terraform.tfstate"
    region         = "eu-west-1"
  }
}

# Declare the AWS Availability Zones data source
data "aws_availability_zones" "available" {
  state = "available"
}

provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster" = "shared"
    "kubernetes.io/role/elb"            = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"   = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name    = "eks-cluster"
  cluster_version = "1.32"  # Ensure a supported version!

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    default = {
      name           = "eks-node-group"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

module "eks_aws-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.33.1"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = var.iam_role_arn
      username = "Eks"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_users = [
    {
      userarn  = var.iam_user_arn
      username = var.iam_username
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = ["597088032758"]
}

