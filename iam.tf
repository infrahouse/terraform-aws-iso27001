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
  # Resource = "*" because this role must operate on every log group in the
  # account (retention enforcement + Vanta-exclusion tagging of Control
  # Tower-managed groups). logs:DescribeLogGroups does not support
  # resource-level permissions; the other actions cover only log-group ARNs
  # in this account by definition. See .checkov.yml for CKV_AWS_111 /
  # CKV_AWS_356 suppressions.
  statement {
    actions = [
      "logs:DescribeLogGroups",
      "logs:ListTagsForResource",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
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
