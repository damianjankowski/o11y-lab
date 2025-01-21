resource "aws_s3_bucket" "this" {
  bucket = var.name

  tags = local.tags

  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_status
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = length(keys(var.server_side_encryption_configuration)) > 0 ? 1 : 0

  bucket                = aws_s3_bucket.this.id
  expected_bucket_owner = var.expected_bucket_owner

  dynamic "rule" {
    for_each = try(flatten([var.server_side_encryption_configuration["rule"]]), [])

    content {
      bucket_key_enabled = try(rule.value.bucket_key_enabled, null)

      dynamic "apply_server_side_encryption_by_default" {
        for_each = try([rule.value.apply_server_side_encryption_by_default], [])

        content {
          sse_algorithm     = apply_server_side_encryption_by_default.value.sse_algorithm
          kms_master_key_id = try(apply_server_side_encryption_by_default.value.kms_master_key_id, null)
        }
      }
    }
  }
}