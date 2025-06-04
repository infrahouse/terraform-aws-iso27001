data "aws_vpcs" "aws-control-tower-VPC" {
  filter {
    name = "tag:Name"
    values = [
      "aws-controltower-VPC"
    ]
  }
}

resource "aws_default_security_group" "default" {
  for_each = toset(data.aws_vpcs.aws-control-tower-VPC.ids)
  vpc_id   = each.key
}
