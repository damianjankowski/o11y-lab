variable "function_name" {
  description = "The name assigned to the Lambda function."
  type        = string
}

variable "handler" {
  description = "The URI of the container image used by the Lambda function."
  type        = string
  default     = "lambda.handler"
}

variable "environment_variables" {
  description = "A map of environment variables to be set for the Lambda function."
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "api_gateway_execution_arn" {
  description = "The execution ARN of the API Gateway, used to grant invoke permissions to the Lambda function."
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket where the Lambda code is stored"
  type        = string
}

variable "s3_key" {
  description = "S3 key for the Lambda code"
  type        = string
}

variable "publish" {
  description = "Whether to publish a new version of the Lambda function"
  type        = bool
  default     = true
}

variable "lambda_layers_arns" {
  description = "List of ARNs for Lambda layers"
  type        = list(string)
  default     = []
}
