variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# -------------------------------------------
# ECR Module Variables
# -------------------------------------------
variable "force_delete" {
  description = "Enable or disable force deletion of the ECR."
  type        = bool
}

# -------------------------------------------
# Lambda Module Variables
# -------------------------------------------
# variable "s3_key" {
#   description = "S3 key for the Lambda code"
#   type        = string
# }

variable "lambda_layers_arns" {
  description = "List of ARNs for Lambda layers"
  type        = list(string)
  default     = []
}

# -------------------------------------------
# API Gateway Module Variables
# -------------------------------------------
variable "api_gateway_stage_name" {
  description = "The stage name of the API Gateway."
  type        = string
}

variable "environment_variables_dynatrace_open_telemetry" {
  description = ""
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "log_retention" {
  description = ""
  type        = number
}

# -------------------------------------------
# FIREHOSE
# -------------------------------------------
variable "dynatrace_api_url" {
  description = ""
  type        = string
}

variable "dynatrace_access_key" {
  description = ""
  type        = string
}
