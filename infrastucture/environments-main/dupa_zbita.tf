# module activegate_monitoring_role {
#   source = "../modules/cloud-snippets/aws/role-based-access/terraform-templates/activegate_monitoring_role"
#
#   active_gate_role_name = "dynatrace_ag_role_name"
#   assume_policy_name    = "dynatrace_assume_policy"
#   monitoring_role_name  = "dynatrace_monitoring_role"
#   monitored_account_id  = "202533497229"
#
#
# }

# module dynatrace_monitoring_role {
#   source = "../modules/cloud-snippets/aws/role-based-access/terraform-templates/dynatrace_monitoring_role"
#
#
#   external_id           = "567bb55a-4005-4dee-b5d1-90c72c1a9aa9"
#
#   # monitored_account_id   = "202533497229"
#   # assume_policy_name     = "sample_dynatrace_assume_policy"
#   # monitoring_role_name   = "sample_dynatrace_monitoring_role"
#   active_gate_account_id = module.activegate_monitoring_role.active_gate_account_id
#   active_gate_role_name  = "sample_ag_dynatrace_monitoring_role"
# }
