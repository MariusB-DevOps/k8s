resource "aws_route_table" "k8s_public_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.k8s_igw_id
  }
    tags = {
        Name        = "k8s_public_rt"
        Environment = "k8s"
        Terraform   = "true"
    }
}

resource "aws_route_table_association" "k8s_public_rt" {
  for_each      = var.public_subnet_map
  subnet_id     = each.value
  route_table_id = aws_route_table.k8s_public_rt.id
}

#resource "aws_route_table" "k8s_private_rt" {
#  vpc_id = var.vpc_id

#  route {
#    cidr_block = "0.0.0.0/0"
#    nat_gateway_id = var.nat_gateway_id
#  }

#  tags = {
#    Name = "private-rt"
#  }
#}

#resource "aws_route_table_association" "k8s_private_rt" {
#  for_each = var.private_subnet_map
#  subnet_id = each.value
#  route_table_id = aws_route_table.k8s_private_rt.id
#}
