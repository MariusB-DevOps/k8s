data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_subnet" {
  for_each                = toset(var.public_subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[index(var.public_subnet_cidrs, each.value)]
    tags = {
        Name        = "public-subnet-${each.value}"
        Environment = "k8s"
        Terraform   = "true"
    }
}

resource "aws_subnet" "private_subnet" {
  for_each                = toset(var.private_subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[index(var.private_subnet_cidrs, each.value)]
    tags = {
        Name        = "private-subnet-${each.value}"
        Environment = "k8s"
        Terraform   = "true"
    }
}
