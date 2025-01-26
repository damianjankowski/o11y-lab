variable "monitored_account_id" {
  description = "ID of the account that Dynatrace should monitor"
  type        = string
}

variable "external_id" {
  description = "External ID, copied from Settings > Cloud and virtualization > AWS in Dynatrace"
  type        = string
}