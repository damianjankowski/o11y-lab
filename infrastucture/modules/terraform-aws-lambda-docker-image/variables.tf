variable "function_name" {
  description = "The name assigned to the Lambda function."
  type        = string
}

variable "image_uri" {
  description = "The URI of the container image used by the Lambda function."
  type        = string
}

variable "architecture" {
  description = "The architecture type for the Lambda function. Valid options include 'x86_64' and 'arm64'."
  type        = list(string)
  default     = ["x86_64"]
}

variable "environment_variables" {
  description = "A map of environment variables to be set for the Lambda function."
  type        = map(string)
}

variable "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway, used to grant invoke permissions to the Lambda function."
  type        = string
}
