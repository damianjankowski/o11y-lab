variable "terraform_remote_state_bucket_name" {}

data "terraform_remote_state" "master_main" {
  backend = "s3"
  config = {
    key            = "env-main.tfstate"
    bucket         = var.terraform_remote_state_bucket_name
    region         = "eu-west-1"
  }
}

variable "aws_account_id" {}

resource "dynatrace_aws_credentials" "aws" {
  label          = "AWS-o11y-lab-DJ"
  partition_type = "AWS_CN"
  tagged_only    = false
  authentication_data {
    account_id = var.aws_account_id
    iam_role   = data.terraform_remote_state.master_main.outputs.monitoring_role
  }
  remove_defaults = false
}

data "dynatrace_aws_supported_services" "supported_services" {
}

resource "dynatrace_aws_service" "services" {
  for_each = data.dynatrace_aws_supported_services.supported_services.services
  credentials_id = dynatrace_aws_credentials.aws.id
  use_recommended_metrics = true
  name           = each.key
}









variable "terraform_remote_state_bucket_name" {}

data "terraform_remote_state" "master_main" {
  backend = "s3"
  config = {
    key    = "env-main.tfstate"
    bucket = var.terraform_remote_state_bucket_name
    region = "eu-west-1"
  }
}

variable "aws_account_id" {}

resource "dynatrace_aws_credentials" "aws" {
  label          = "AWS-o11y-lab-DJ"
  partition_type = "AWS_CN"
  tagged_only    = false
  authentication_data {
    account_id = var.aws_account_id
    iam_role   = data.terraform_remote_state.master_main.outputs.monitoring_role
  }
  remove_defaults = true
}

data "dynatrace_aws_supported_services" "supported_services" {}

resource "dynatrace_aws_service" "services" {
  for_each                = toset(data.dynatrace_aws_supported_services.supported_services.services)
  name                    = each.value
  credentials_id          = dynatrace_aws_credentials.aws.id
  use_recommended_metrics = true
}

locals {
  builtin_services = [
    "s3_builtin",
    "rds_builtin",
    "loadbalancer_builtin",
    "lambda_builtin",
    "ELB_builtin",
    "ec2_builtin",
    "ebs_builtin",
    "dynamodb_builtin",
    "asg_builtin"
  ]
}

resource "dynatrace_aws_service" "builtin_services" {
  for_each       = toset(local.builtin_services)
  name           = each.value
  credentials_id = dynatrace_aws_credentials.aws.id
}

resource "dynatrace_aws_service" "APIGateway" {
  name           = "APIGateway"
  credentials_id = "AWS_CREDENTIALS-A9AA319512DDC9A3"
  metric {
    name       = "4XXError"
    dimensions = [ "ApiName" ]
    statistic  = "SUM"
  }
  metric {
    name       = "5XXError"
    dimensions = [ "ApiName" ]
    statistic  = "SUM"
  }
  metric {
    name       = "Count"
    dimensions = [ "ApiName" ]
    statistic  = "SUM"
  }
  metric {
    name       = "IntegrationLatency"
    dimensions = [ "ApiName" ]
    statistic  = "AVG_MIN_MAX"
  }
  metric {
    name       = "Latency"
    dimensions = [ "ApiName" ]
    statistic  = "AVG_MIN_MAX"
  }
  metric {
    name       = "4XXError"
    dimensions = [ "ApiName", "Stage" ]
    statistic  = "SUM"
  }
  metric {
    name       = "4XXError"
    dimensions = [ "ApiName", "Stage", "Resource", "Method" ]
    statistic  = "SUM"
  }
  metric {
    name       = "5XXError"
    dimensions = [ "ApiName", "Stage" ]
    statistic  = "SUM"
  }
  metric {
    name       = "5XXError"
    dimensions = [ "ApiName", "Stage", "Resource", "Method" ]
    statistic  = "SUM"
  }
  metric {
    name       = "Count"
    dimensions = [ "ApiName", "Stage" ]
    statistic  = "SUM"
  }
  metric {
    name       = "Count"
    dimensions = [ "Region" ]
    statistic  = "SUM"
  }
  metric {
    name       = "Count"
    dimensions = [ "ApiName", "Stage", "Resource", "Method" ]
    statistic  = "SUM"
  }
  metric {
    name       = "IntegrationLatency"
    dimensions = [ "ApiName", "Stage" ]
    statistic  = "AVG_MIN_MAX"
  }
  metric {
    name       = "IntegrationLatency"
    dimensions = [ "ApiName", "Stage", "Resource", "Method" ]
    statistic  = "AVG_MIN_MAX"
  }
  metric {
    name       = "Latency"
    dimensions = [ "ApiName", "Stage" ]
    statistic  = "AVG_MIN_MAX"
  }
  metric {
    name       = "Latency"
    dimensions = [ "ApiName", "Stage", "Resource", "Method" ]
    statistic  = "AVG_MIN_MAX"
  }
  metric {
    name       = "CacheHitCount"
    dimensions = [ "ApiName", "Stage" ]
    statistic  = "SUM"
  }
  metric {
    name       = "CacheHitCount"
    dimensions = [ "ApiName" ]
    statistic  = "SUM"
  }
  metric {
    name       = "CacheHitCount"
    dimensions = [ "ApiName", "Stage", "Resource", "Method" ]
    statistic  = "SUM"
  }
  metric {
    name       = "CacheMissCount"
    dimensions = [ "ApiName" ]
    statistic  = "SUM"
  }
  metric {
    name       = "CacheMissCount"
    dimensions = [ "ApiName", "Stage" ]
    statistic  = "SUM"
  }
  metric {
    name       = "CacheMissCount"
    dimensions = [ "ApiName", "Stage", "Resource", "Method" ]
    statistic  = "SUM"
  }
}





