data "aws_ssm_parameter" "vanta_external_id" {
  name = "/vanta/external_id"
}

data "aws_iam_policy_document" "vanta_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::956993596390:role/scanner"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [data.aws_ssm_parameter.vanta_external_id.value]
    }
  }
}

data "aws_iam_policy_document" "vanta_additional_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "identitystore:DescribeGroup",
      "identitystore:DescribeGroupMembership",
      "identitystore:DescribeUser",
      "identitystore:GetGroupId",
      "identitystore:GetGroupMembershipId",
      "identitystore:GetUserId",
      "identitystore:IsMemberInGroups",
      "identitystore:ListGroupMemberships",
      "identitystore:ListGroupMembershipsForMember",
      "identitystore:ListGroups",
      "identitystore:ListUsers",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Deny"
    actions = [
      "datapipeline:EvaluateExpression",
      "datapipeline:QueryObjects",
      "rds:DownloadDBLogFilePortion",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "vanta_auditor" {
  name               = "vanta-auditor"
  assume_role_policy = data.aws_iam_policy_document.vanta_assume_role.json

  tags = local.default_module_tags
}

data "aws_iam_policy" "security_audit" {
  name = "SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "vanta_security_audit" {
  role       = aws_iam_role.vanta_auditor.name
  policy_arn = data.aws_iam_policy.security_audit.arn
}

resource "aws_iam_policy" "vanta_additional_permissions" {
  name   = "VantaAdditionalPermissions"
  policy = data.aws_iam_policy_document.vanta_additional_permissions.json

  tags = local.default_module_tags
}

resource "aws_iam_role_policy_attachment" "vanta_additional_permissions" {
  role       = aws_iam_role.vanta_auditor.name
  policy_arn = aws_iam_policy.vanta_additional_permissions.arn
}
