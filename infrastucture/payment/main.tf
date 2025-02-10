variable "terraform_remote_state_bucket_name" {}

data "terraform_remote_state" "master_main" {
  backend = "s3"
  config = {
    key            = "env-main.tfstate"
    bucket         = var.terraform_remote_state_bucket_name
    region         = "eu-west-1"
  }
}

# # API_GATEWAY_LOGS
# module "apigateway_log_group" {
#   source            = "../modules/cloudwatch-log-group"
#   log_group_name    = "/aws/apigateway/${local.project_name}-apigateway-logs"
#   log_retention     = var.log_retention
# }


# INITIALIZER
module "lambda_initializer" {
  source = "../modules/terraform-aws-lambda-zip"

  function_name = "${local.project_name}-lambda-payments-initializer"

  api_gateway_execution_arn = module.api_gateway_initializer.execution_arn
  s3_bucket                 = data.terraform_remote_state.master_main.outputs.s3_bucket_name
  s3_key                    = "${local.project_name}-lambda-payments-initializer.zip"
  # DYNATRACE INSTRUMENTATION:
  environment_variables = var.environment_variables_dynatrace_open_telemetry
  lambda_layers_arns    = var.lambda_layers_arns
}

module "api_gateway_initializer" {
  source = "../modules/terraform-aws-apigateway"

  api_gateway_name = "${local.project_name}-initializer"

  openapi_template_file  = "./openapi_definition_initializer.json"
  log_retention          = var.log_retention
  api_gateway_stage_name = var.api_gateway_stage_name
  lambda_arn             = module.lambda_initializer.lambda_arn

}

module "firehose_initializer_api_gateway" {
  source = "../modules/terraform-aws-firehose"

  firehose_name = "${local.project_name}-apigateway-initializer"

  dynatrace_api_url        = var.dynatrace_api_url
  dynatrace_access_key     = var.dynatrace_access_key
  s3_bucket_arn            = data.terraform_remote_state.master_main.outputs.s3_bucket_arn
  aws_cloudwatch_log_group = module.api_gateway_initializer.aws_cloudwatch_log_group
}

module "firehose_initializer_lambda" {
  source = "../modules/terraform-aws-firehose"

  firehose_name = "${local.project_name}-lambda-initializer"

  dynatrace_api_url        = var.dynatrace_api_url
  dynatrace_access_key     = var.dynatrace_access_key
  s3_bucket_arn            = data.terraform_remote_state.master_main.outputs.s3_bucket_arn
  aws_cloudwatch_log_group = module.lambda_initializer.aws_cloudwatch_log_group
}

module "dynamodb_table_show_me_the_money" {
  source       = "../modules/terraform-aws-dynamodb"
  table_name   = "ShowMeTheMoney"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "payment_id"
  range_key    = null

  attributes = [
    { name = "payment_id", type = "S" }
  ]

  enable_ttl    = true
  ttl_attribute = "ttl_timestamp"

  tags = {
    Name = "ShowMeTheMoney"
  }
}

# FINALIZER
module "lambda_finalizer" {
  source = "../modules/terraform-aws-lambda-zip"

  function_name = "${local.project_name}-lambda-payments-finalizer"

  api_gateway_execution_arn = module.api_gateway_finalizer.execution_arn
  s3_bucket                 = data.terraform_remote_state.master_main.outputs.s3_bucket_name
  s3_key                    = "${local.project_name}-lambda-payments-finalizer.zip"
  # DYNATRACE INSTRUMENTATION:
  environment_variables = var.environment_variables_dynatrace_open_telemetry
  lambda_layers_arns    = var.lambda_layers_arns
}

module "api_gateway_finalizer" {
  source = "../modules/terraform-aws-apigateway"

  api_gateway_name = "${local.project_name}-finalizer"

  log_retention          = var.log_retention
  api_gateway_stage_name = var.api_gateway_stage_name
  openapi_template_file  = "./openapi_definition_finalizer.json"
  lambda_arn             = module.lambda_finalizer.lambda_arn

}

module "firehose_finalizer_api_gateway" {
  source = "../modules/terraform-aws-firehose"

  firehose_name = "${local.project_name}-apigateway-finalizer"

  dynatrace_api_url        = var.dynatrace_api_url
  dynatrace_access_key     = var.dynatrace_access_key
  s3_bucket_arn            = data.terraform_remote_state.master_main.outputs.s3_bucket_arn
  aws_cloudwatch_log_group = module.api_gateway_finalizer.aws_cloudwatch_log_group
}

module "firehose_finalizer_lambda" {
  source = "../modules/terraform-aws-firehose"

  firehose_name = "${local.project_name}-lambda-finalizer"

  dynatrace_api_url        = var.dynatrace_api_url
  dynatrace_access_key     = var.dynatrace_access_key
  s3_bucket_arn            = data.terraform_remote_state.master_main.outputs.s3_bucket_arn
  aws_cloudwatch_log_group = module.lambda_finalizer.aws_cloudwatch_log_group
}

module "dynamodb_table_breaking_the_bank" {
  source       = "../modules/terraform-aws-dynamodb"
  table_name   = "BreakingTheBank"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PaymentID"
  range_key    = null

  attributes = [
    { name = "PaymentID", type = "S" },
  ]

  enable_ttl    = true
  ttl_attribute = "ttl_timestamp"

  tags = {
    Name        = "BreakingTheBank"
    Environment = "production"
  }
}

# EVENT BRIDGE
resource "aws_cloudwatch_event_bus" "event_bus" {
  name = "${local.project_name}-event-bus"
}

module "payment_initiated_rule" {
  source = "../modules/terraform-aws-event-bridge"

  event_bus_name  = aws_cloudwatch_event_bus.event_bus.name
  event_rule_name = "payment_initiated_rule"
  event_pattern = jsonencode({
    "source"        = ["payments.initializator"]
    "detail-type" = ["payment.initiated"]
  })
  lambda_arn           = module.lambda_finalizer.lambda_arn
  lambda_function_name = module.lambda_finalizer.function_name
}
