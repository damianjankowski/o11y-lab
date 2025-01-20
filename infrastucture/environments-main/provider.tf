variable "aws_region" {
}

variable "aws_account_id" {
}

provider "aws" {

  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.aws_account_id}:role/TerraformGitHub"
  # }
}
