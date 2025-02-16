resource "aws_key_pair" "k8s_key" {
    key_name   = var.key_pair_name
    public_key = var.public_key_content

    tags = {
        Name        = "k8s"
        Environment = "devops"
        Terraform   = "true"
    }
}
