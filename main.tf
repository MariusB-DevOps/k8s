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
  public_key_content = var.public_key_content
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
  ingress_controller_public_dns = var.ingress_controller_public_dns
  ingress_controller_zone_id = var.ingress_controller_zone_id
}

module "jenkins" {
  source = "./modules/jenkins"

  jenkins_namespace = var.jenkins_namespace
  jenkins_release_name = var.jenkins_release_name
  jenkins_ingress_host = var.jenkins_ingress_host
  jenkins_persistence_size = var.jenkins_persistence_size
  jenkins_java_opts = var.jenkins_java_opts
  jenkins_resources_requests_cpu = var.jenkins_resources_requests_cpu
  jenkins_resources_requests_memory = var.jenkins_resources_requests_memory
  jenkins_resources_limits_cpu = var.jenkins_resources_limits_cpu
  jenkins_resources_limits_memory = var.jenkins_resources_limits_memory
}
