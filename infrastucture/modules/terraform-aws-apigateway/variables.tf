variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_gateway_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "API Gateway integrated with Lambda"
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
}

variable "lambda_arn" {
  description = "The ARN of the Lambda function"
  type        = string
  default     = ""
}

variable "openapi_template_file" {
  description = ""
  type        = string
}

variable "logging_level" {
  description = ""
  type        = string
  default     = "INFO"
}

variable "metrics_enabled" {
  description = ""
  type        = bool
  default     = true
}

variable "data_trace_enabled" {
  description = ""
  type        = string
  default     = true
}

variable "log_retention" {
  description = ""
  type        = number
}
