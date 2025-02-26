provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"   # Amazon ECS-Optimized Amazon Linux 2
  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 3
      desired_size = 2
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

  aws_auth_accounts = [
    "597088032758",
  ]
}
