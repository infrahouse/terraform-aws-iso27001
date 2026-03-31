resource "aws_ebs_encryption_by_default" "this" {
  for_each = toset(var.regions)
  enabled  = true
  region   = each.key
}
