resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = var.vpc_id
    tags = {
        Name        = "k8s_igw"
        Environment = "k8s"
        Terraform   = "true"
    }
}

resource "aws_nat_gateway" "k8s_ngw" {
  allocation_id = aws_eip.k8s_ngw.id
  subnet_id     = element(var.public_subnet_ids, 0)

  tags = {
    Name = "main-nat"
  }
}

resource "aws_eip" "k8s_ngw" {
  domain = "vpc"
}
