resource "aws_kms_key" "o11y_lab_secrets" {
  description = "A key for encryption of terraform secrets in Parameter Store"
}

resource "aws_kms_alias" "o11y_lab_secrets" {
  name          = "alias/o11y-lab/secrets"
  target_key_id = aws_kms_key.o11y_lab_secrets.key_id
}


