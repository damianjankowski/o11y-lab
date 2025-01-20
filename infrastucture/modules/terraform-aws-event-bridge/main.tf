variable "event_bus_name" {}
variable "event_rule_name" {}
variable "event_pattern" {}
variable "lambda_arn" {}
variable "lambda_function_name" {}

resource "aws_cloudwatch_event_rule" "rule" {
  name           = var.event_rule_name
  event_bus_name = var.event_bus_name
  event_pattern  = var.event_pattern
}

resource "aws_cloudwatch_event_target" "target" {
  rule           = aws_cloudwatch_event_rule.rule.name
  target_id      = var.event_rule_name
  arn            = var.lambda_arn
  event_bus_name = var.event_bus_name
}

resource "aws_lambda_permission" "allow_eventbridge" {
  depends_on = [aws_cloudwatch_event_rule.rule]

  statement_id  = "AllowExecutionFromEventBridge-${var.event_rule_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rule.arn
}