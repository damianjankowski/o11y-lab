variable "terraform_remote_state_bucket_name" {}

data "terraform_remote_state" "master_main" {
  backend = "s3"
  config = {
    key            = "main.tfstate"
    bucket         = var.terraform_remote_state_bucket_name
    region         = "eu-west-1"
  }
}

