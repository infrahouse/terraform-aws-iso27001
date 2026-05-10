data "aws_iam_policy_document" "s3_batch_replication_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["batchoperations.s3.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_batch_replication_permissions" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:PutInventoryConfiguration",
    ]
    resources = ["arn:aws:s3:::*"]
  }
  statement {
    actions   = ["s3:InitiateReplication"]
    resources = ["arn:aws:s3:::*/*"]
  }
}

resource "aws_iam_role" "s3_batch_replication" {
  name               = "s3-batch-replication"
  assume_role_policy = data.aws_iam_policy_document.s3_batch_replication_trust.json
}

resource "aws_iam_role_policy" "s3_batch_replication" {
  name   = "s3-batch-replication"
  role   = aws_iam_role.s3_batch_replication.name
  policy = data.aws_iam_policy_document.s3_batch_replication_permissions.json
}
