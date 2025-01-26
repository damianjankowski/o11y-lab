data "aws_caller_identity" "current" {}

locals {
  principals_identifiers = var.active_gate_account_id == null || var.active_gate_role_name == null ? [
    "509560245411" # Dynatrace monitoring account ID
    ] : [
    "509560245411", # Dynatrace monitoring account ID
    "arn:aws:iam::${var.active_gate_account_id}:role/${var.active_gate_role_name}"
  ]
}
data "aws_iam_policy_document" "dynatrace_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.principals_identifiers
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        var.external_id,
      ]
    }
  }
}

data "aws_iam_policy_document" "dynatrace_aws_integration" {
  statement {
    actions = [
      "acm-pca:ListCertificateAuthorities",
      "apigateway:GET",
      "appstream:DescribeFleets",
      "appsync:ListGraphqlApis",
      "athena:ListWorkGroups",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "cloudformation:DescribeStacks",
      "cloudformation:ListStackResources",
      "cloudfront:ListDistributions",
      "cloudhsm:DescribeClusters",
      "cloudsearch:DescribeDomains",
      "cloudtrail:LookupEvents",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "codebuild:ListProjects",
      "codepipeline:ListPipelines",
      "datasync:ListTasks",
      "dax:DescribeClusters",
      "directconnect:DescribeConnections",
      "dms:DescribeReplicationInstances",
      "dynamodb:DescribeTable",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeNatGateways",
      "ec2:DescribeSpotFleetRequests",
      "ec2:DescribeTransitGateways",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpnConnections",
      "ecs:DescribeClusters",
      "ecs:ListClusters",
      "eks:DescribeCluster",
      "eks:ListClusters",
      "elasticache:DescribeCacheClusters",
      "elasticbeanstalk:DescribeEnvironmentResources",
      "elasticbeanstalk:DescribeEnvironments",
      "elasticfilesystem:DescribeFileSystems",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticmapreduce:ListClusters",
      "elastictranscoder:ListPipelines",
      "es:ListDomainNames",
      "events:ListEventBuses",
      "firehose:ListDeliveryStreams",
      "fsx:DescribeFileSystems",
      "gamelift:ListFleets",
      "glue:GetJobs",
      "inspector:ListAssessmentTemplates",
      "kafka:ListClusters",
      "kinesis:ListStreams",
      "kinesisanalytics:ListApplications",
      "kinesisvideo:ListStreams",
      "lambda:ListFunctions",
      "lambda:ListTags",
      "lex:GetBots",
      "logs:DescribeLogGroups",
      "mediaconnect:ListFlows",
      "mediaconvert:DescribeEndpoints",
      "mediapackage-vod:ListPackagingConfigurations",
      "mediapackage:ListChannels",
      "mediatailor:ListPlaybackConfigurations",
      "opsworks:DescribeStacks",
      "qldb:ListLedgers",
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds:DescribeEvents",
      "rds:ListTagsForResource",
      "redshift:DescribeClusters",
      "robomaker:ListSimulationJobs",
      "route53:ListHostedZones",
      "route53resolver:ListResolverEndpoints",
      "s3:ListAllMyBuckets",
      "sagemaker:ListEndpoints",
      "sns:ListTopics",
      "sqs:ListQueues",
      "storagegateway:ListGateways",
      "sts:GetCallerIdentity",
      "swf:ListDomains",
      "tag:GetResources",
      "tag:GetTagKeys",
      "transfer:ListServers",
      "workmail:ListOrganizations",
      "workspaces:DescribeWorkspaces",
      "xray:GetTraceSummaries",
      "xray:GetServiceGraph"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "dynatrace_aws_integration" {
  name   = "DynatraceAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.dynatrace_aws_integration.json
}

resource "aws_iam_role" "dynatrace_aws_integration" {
  name               = "DynatraceAWSIntegrationRole"
  description        = "Role for Dynatrace AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.dynatrace_aws_integration_assume_role.json
}

resource "aws_iam_role_policy_attachment" "dynatrace_aws_integration" {
  role       = aws_iam_role.dynatrace_aws_integration.name
  policy_arn = aws_iam_policy.dynatrace_aws_integration.arn
}


# resource "aws_ssm_parameter" "dynatrace_oauth_id" {
#   name        = "/terraform/dynatrace/oauth-id"
#   description = "Dynatrace OAuth Client ID"
#   type        = "SecureString"
#   value       = "<TO_BE_UPDATED>"
#
#   lifecycle {
#     ignore_changes = [
#       value
#     ]
#   }
# }
#
# resource "aws_ssm_parameter" "dynatrace_oauth_secret" {
#   name        = "/terraform/dynatrace/oauth-secret"
#   description = "Dynatrace OAuth Secret"
#   type        = "SecureString"
#   value       = "<TO_BE_UPDATED>"
#
#   lifecycle {
#     ignore_changes = [
#       value
#     ]
#   }
# }


