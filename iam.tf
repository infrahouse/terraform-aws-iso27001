data "aws_iam_policy_document" "AWSControlTowerExecution-trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = [
        for role_name in ["AWSControlTowerAdmin", "AWSControlTowerStackSetRole"] :
        "arn:aws:iam::${data.aws_organizations_organization.current.master_account_id}:role/service-role/${role_name}"
      ]
      type = "AWS"
    }
  }
}

data "aws_iam_policy" "AdministratorAccess" {
  name = "AdministratorAccess"
}

resource "aws_iam_role" "AWSControlTowerExecution" {
  count              = data.aws_region.current.name == "us-east-1" ? 1 : 0
  name               = "AWSControlTowerExecution"
  assume_role_policy = data.aws_iam_policy_document.AWSControlTowerExecution-trust.json
}

resource "aws_iam_role_policy_attachment" "AdministratorAccess" {
  count      = data.aws_region.current.name == "us-east-1" ? 1 : 0
  policy_arn = data.aws_iam_policy.AdministratorAccess.arn
  role       = aws_iam_role.AWSControlTowerExecution[count.index].name
}
