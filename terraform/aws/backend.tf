terraform {
  backend "s3" {
    bucket         = "mariusb-tf-state"
    key            = "terraform/state/terraform.tfstate"
    region         = "eu-west-1"
  }
}
