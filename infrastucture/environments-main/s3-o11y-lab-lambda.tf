locals {
  project_name = "o11y-lab"
  environment = "0x44616D69616E"
}

variable "kms_master_key_id" {}

module "s3_o11y_lab_apps" {
  source = "../modules/terraform-aws-s3"

  name = "${local.project_name}-s3-bucket"

  tags = {
    project: local.project_name
    env: local.environment
  }

  force_destroy = true

  versioning_status = "Enabled"

  server_side_encryption_configuration = {
    rule = [
      {
        bucket_key_enabled = true
        apply_server_side_encryption_by_default = {
          sse_algorithm     = "aws:kms"
          kms_master_key_id = var.kms_master_key_id
        }
      }
    ]
  }
}

output "s3_bucket_id" {
  value = module.s3_o11y_lab_apps.s3_bucket_id
}

output "s3_bucket_name" {
  value = module.s3_o11y_lab_apps.s3_bucket_name
}

output "s3_bucket_arn" {
  value = module.s3_o11y_lab_apps.s3_bucket_arn
}
