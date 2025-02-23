provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
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

    two = {
      name = "node-group-2"

      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
}

# Configure aws-auth ConfigMap
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.eks_deployer.arn}
  username: eks-deployer
  groups:
    - system:masters
- rolearn: ${var.iam_role_arn}
  username: eks-deployer
  groups:
    - system:masters
YAML

    mapUsers = <<YAML
- userarn: ${var.iam_user_arn}
  username: ${var.iam_username}
  groups:
    - system:masters
YAML
  }

  depends_on = [module.eks]
}

# IAM Role for EKS Deployer
resource "aws_iam_role" "eks_deployer" {
  name = "eks-deployer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.assume_role_principal_arn # Allow your root account to assume this role.
        }
      },
    ]
  })
}

# Attach AdministratorAccess Policy to the Role
resource "aws_iam_role_policy_attachment" "eks_deployer_policy" {
  role       = aws_iam_role.eks_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # or any other policy you want to attach.
}
