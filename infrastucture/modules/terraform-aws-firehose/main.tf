# ---------------------------------------------------
# IAM Policy Document for Firehose to assume the role
# ---------------------------------------------------
data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ---------------------------------------------------
# IAM Role for Firehose
# ---------------------------------------------------
resource "aws_iam_role" "firehose_role" {
  name               = "${var.firehose_name}-firehose-iam-role"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

# ---------------------------------------------------
# IAM Policy Document for Firehose - permissions
# ---------------------------------------------------
data "aws_iam_policy_document" "firehose_policy" {
  statement {
    effect = "Allow"

    actions = [
      # "firehose:DeleteDeliveryStream",
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
      # "firehose:UpdateDestination",
      # "logs:CreateLogGroup",
      # "logs:CreateLogStream",
      # "logs:PutLogEvents",
      # "s3:AbortMultipartUpload",
      # "s3:GetBucketLocation",
      # "s3:GetObject",
      # "s3:ListBucket",
      # "s3:ListBucketMultipartUploads",
      # "s3:PutObject",
      # "kinesis:DescribeStream",
      # "kinesis:GetShardIterator",
      # "kinesis:GetRecords",
      # "kinesis:ListShards"
    ]

    resources = ["*"] # Replace '*' with a specific ARN for stricter permissions if needed
  }
}

# ---------------------------------------------------
# IAM Policy for Firehose
# ---------------------------------------------------
resource "aws_iam_policy" "firehose_policy" {
  name        = "${var.firehose_name}-firehose-iam-policy"
  description = "IAM policy for Firehose"
  policy      = data.aws_iam_policy_document.firehose_policy.json
}

# ---------------------------------------------------
# Attach IAM Policy to Firehose Role
# ---------------------------------------------------
resource "aws_iam_role_policy_attachment" "firehose_policy_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

# ---------------------------------------------------
# IAM Policy Document for CloudWatch Logs to assume the role
# ---------------------------------------------------
data "aws_iam_policy_document" "cloudwatch_assume_role" {
  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# ---------------------------------------------------
# IAM Role for CloudWatch Logs
# ---------------------------------------------------
resource "aws_iam_role" "cloudwatch_role" {
  name               = "${var.firehose_name}-cloudwatch-iam-role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_assume_role.json
}

# ---------------------------------------------------
# IAM Policy Document for CloudWatch Role - permissions to Firehose
# ---------------------------------------------------
data "aws_iam_policy_document" "cloudwatch_policy" {
  statement {
    effect = "Allow"

    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]

    resources = [aws_kinesis_firehose_delivery_stream.this.arn]
  }
}

# ---------------------------------------------------
# IAM Policy for CloudWatch Role
# ---------------------------------------------------
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "${var.firehose_name}-cloudwatch-iam-policy"
  description = "IAM policy for CloudWatch Logs to Firehose"
  policy      = data.aws_iam_policy_document.cloudwatch_policy.json
}

# ---------------------------------------------------
# Attach IAM Policy to CloudWatch Role
# ---------------------------------------------------
resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attachment" {
  role       = aws_iam_role.cloudwatch_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

locals {
  # firehose_stream_name         = "traffiq-terraform-kinesis-firehose-dynatrace-stream"
  firehose_stream_name         = "${var.firehose_name}-firehose-dynatrace-stream"
  firehose_log_group_http      = "/aws/firehose/traffiq-terraform-kinesis-firehose-dynatrace-stream/HttpEndpoint"
  firehose_log_group_s3_backup = "/aws/firehose/traffiq-terraform-kinesis-firehose-dynatrace-stream/S3Backup"
}

# ---------------------------------------------------
# Kinesis Firehose Delivery Stream
# ---------------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = local.firehose_stream_name
  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = var.dynatrace_api_url
    name               = "Dynatrace"
    access_key         = var.dynatrace_access_key
    retry_duration     = 900
    buffering_size     = 1
    buffering_interval = 60
    role_arn           = aws_iam_role.firehose_role.arn

    s3_backup_mode = "FailedDataOnly"

    s3_configuration {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = var.s3_bucket_arn
      prefix             = "firehose-backup/"
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "GZIP"

      # cloudwatch_logging_options {
      #   enabled         = true
      #   log_group_name  = local.firehose_log_group_s3_backup
      #   log_stream_name = "S3BackupLogs"
      # }
    }

    # cloudwatch_logging_options {
    #   enabled         = true
    #   log_group_name  = local.firehose_log_group_http
    #   log_stream_name = "HttpEndpointLogs"
    # }
  }

  tags = {
    Name = "${var.firehose_name}-terraform-kinesis-firehose-dynatrace-stream"
  }
}

# ---------------------------------------------------
# CloudWatch Log Subscription Filter
# ---------------------------------------------------
resource "aws_cloudwatch_log_subscription_filter" "logfilter" {
  depends_on = [
    aws_kinesis_firehose_delivery_stream.this,
    aws_iam_role_policy_attachment.firehose_policy_attachment,
    aws_iam_role_policy_attachment.cloudwatch_policy_attachment
  ]

  name            = "${var.firehose_name}-log-subscription-filter"
  role_arn        = aws_iam_role.cloudwatch_role.arn
  log_group_name  = var.aws_cloudwatch_log_group
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.this.arn
}
