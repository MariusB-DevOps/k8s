resource "aws_key_pair" "k8s_key" {
    key_name        = var.key_pair_name
    public_key      = file(var.public_key_path)
    tags = {
        Name        = "k8s"
        Environment = "devops"
        Terraform   = "true"
    }
}
