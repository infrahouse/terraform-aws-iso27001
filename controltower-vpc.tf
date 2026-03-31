data "aws_vpcs" "aws_control_tower_vpc" {
  for_each = toset(var.regions)
  region   = each.key
  filter {
    name = "tag:Name"
    values = [
      "aws-controltower-VPC"
    ]
  }
}

resource "aws_default_security_group" "default" {
  for_each = local.controltower_vpcs
  vpc_id   = each.value.vpc_id
  region   = each.value.region
}
