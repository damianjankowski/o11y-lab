variable "log_group_name" {
  description = ""
  type        = string
}

variable "log_retention" {
  description = ""
  type        = number
  default = 30
}

resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.log_retention
}

output "log_group_arn" {
  value = aws_cloudwatch_log_group.this.arn
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}
