output "kms_terraform_secrets_key_arn" {
  value = aws_kms_key.terraform_secrets.arn
}

output "kms_terraform_secrets_key_alias_arn" {
  value = aws_kms_alias.terraform_secrets.arn
}