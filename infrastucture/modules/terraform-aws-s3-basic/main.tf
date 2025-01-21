resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Owner       = "DJ"
    Environment = "Dev"
  }
}
