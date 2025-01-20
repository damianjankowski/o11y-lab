resource "aws_kms_key" "terraform_secrets" {
  description = "A key for encryption of terraform secrets in Parameter Store"
}

resource "aws_kms_alias" "terraform_secrets" {
  name          = "alias/tf/secrets"
  target_key_id = aws_kms_key.terraform_secrets.key_id
}


