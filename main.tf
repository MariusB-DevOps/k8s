provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = var.vpc_cidr
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames
}

module "igw" {
  source = "./modules/igw"

  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.subnet.public_subnet_ids
}

module "network_interfaces" {
  source = "./modules/network_interfaces"

  public_subnet_ids = module.subnet.public_subnet_ids
  private_subnet_ids = module.subnet.private_subnet_ids
  security_group_id = module.security_group.sg_id
}

module "route_table" {
  source = "./modules/route_table"

  vpc_id = module.vpc.vpc_id
  k8s_igw_id = module.igw.k8s_igw_id
  public_subnet_map = { for idx, id in module.subnet.public_subnet_ids : idx => id }
}

module "security_group" {
  source = "./modules/security_group"

  vpc_id = module.vpc.vpc_id
  allowed_cidr = var.allowed_cidr
}

module "ssh_key" {
  source = "./modules/ssh_key"

  key_pair_name = var.key_pair_name
  public_key_path = var.public_key_path
}

module "subnet" {
  source = "./modules/subnet"

  vpc_id = module.vpc.vpc_id
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnet.private_subnet_ids

  desired_capacity = var.desired_capacity
  max_capacity     = var.max_capacity
  min_capacity     = var.min_capacity
  instance_type    = var.instance_type
  environment      = var.environment
}

module "route53" {
  source = "./modules/route53"

  route53_zone_id = "Z05844171BN27HQQ98YZ8"
  jenkins_ingress_host = var.jenkins_ingress_host
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
  }
}

resource "helm_release" "jenkins" {
  name       = var.jenkins_release_name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  set {
    name  = "controller.ingress.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingress.hostName"
    value = var.jenkins_ingress_host
  }

  set {
    name  = "controller.ingress.annotations.nginx.ingress.kubernetes.io/force-ssl-redirect"
    value = "true"
  }

  set {
    name  = "controller.ingress.annotations.nginx.ingress.kubernetes.io/ssl-redirect"
    value = "true"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = var.jenkins_persistence_size
  }

  set {
    name  = "controller.javaOpts"
    value = var.jenkins_java_opts
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = var.jenkins_resources_requests_cpu
  }

  set {
    name  = "controller.resources.requests.memory"
    value = var.jenkins_resources_requests_memory
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = var.jenkins_resources_limits_cpu
  }

  set {
    name  = "controller.resources.limits.memory"
    value = var.jenkins_resources_limits_memory
  }
}
