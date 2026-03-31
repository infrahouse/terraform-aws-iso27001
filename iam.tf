data "aws_iam_policy_document" "InfraHouseLogRetention-trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["arn:aws:iam::${data.aws_organizations_organization.current.master_account_id}:root"]
      type        = "AWS"
    }
  }
}

data "aws_iam_policy_document" "InfraHouseLogRetention-permissions" {
  statement {
    actions = [
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "InfraHouseLogRetention" {
  name               = "InfraHouseLogRetention"
  assume_role_policy = data.aws_iam_policy_document.InfraHouseLogRetention-trust.json
}

resource "aws_iam_role_policy" "InfraHouseLogRetention" {
  name   = "InfraHouseLogRetention"
  role   = aws_iam_role.InfraHouseLogRetention.name
  policy = data.aws_iam_policy_document.InfraHouseLogRetention-permissions.json
}
