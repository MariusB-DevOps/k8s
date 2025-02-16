resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
        Name        = "k8s_vpc"
        Environment = "k8s"
        Terraform   = "true"
    }
}
