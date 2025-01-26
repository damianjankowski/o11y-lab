output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "IAM role that Dynatrace should use to get monitoring data"
}

output "role_name" {
  value       = aws_iam_role.dynatrace_aws_integration.name
  description = "IAM role that Dynatrace should use to get monitoring data"
}



# output "dynatrace_oauth_secret_ssm_key_name" {
#   value = aws_ssm_parameter.dynatrace_oauth_secret.name
# }
#
# output "dynatrace_oauth_id_ssm_key_name" {
#   value = aws_ssm_parameter.dynatrace_oauth_id.name
# }
