# InfraHouseGovernance is assumed cross-account by the terraform-aws-org-governance
# Lambda and covers the broader set of read+tag operations that module needs
# (currently log-group retention/tagging plus tagging Control Tower-managed
# Lambda functions with VantaNoAlert=true). It supersedes InfraHouseLogRetention
# (see iam-log-retention.tf), which will be removed in the next major release.
data "aws_iam_policy_document" "InfraHouseGovernance-trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["arn:aws:iam::${data.aws_organizations_organization.current.master_account_id}:root"]
      type        = "AWS"
    }
  }
}

data "aws_iam_policy_document" "InfraHouseGovernance-permissions" {
  # Resource = "*" because this role operates on every log group and every
  # Lambda function in the account. logs:DescribeLogGroups and
  # lambda:ListFunctions do not support resource-level permissions; the
  # remaining actions cover only resource ARNs in this account by definition.
  # See .checkov.yml for CKV_AWS_111 / CKV_AWS_356 suppressions.
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
  statement {
    actions = [
      "lambda:ListFunctions",
      "lambda:ListTags",
      "lambda:TagResource",
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:GetBucketTagging",
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "InfraHouseGovernance" {
  name               = "InfraHouseGovernance"
  assume_role_policy = data.aws_iam_policy_document.InfraHouseGovernance-trust.json
}

resource "aws_iam_role_policy" "InfraHouseGovernance" {
  name   = "InfraHouseGovernance"
  role   = aws_iam_role.InfraHouseGovernance.name
  policy = data.aws_iam_policy_document.InfraHouseGovernance-permissions.json
}
