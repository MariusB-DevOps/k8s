resource "aws_network_interface" "public" {
  count           = 1
  subnet_id       = element(var.public_subnet_ids, 0)
  security_groups = [var.security_group_id]

  tags = {
    Name = "public-nic-${count.index}"
  }
}

resource "aws_network_interface" "private" {
  count           = 3
  subnet_id       = element(var.private_subnet_ids, count.index)
  security_groups = [var.security_group_id]

  tags = {
    Name = "private-nic-${count.index}"
  }
}
