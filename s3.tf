resource "aws_s3_account_public_access_block" "current" {
  count = data.aws_region.current.name == "us-east-1" ? 1 : 0
  ignore_public_acls      = true
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}
