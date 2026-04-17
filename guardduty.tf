resource "aws_guardduty_detector" "main" {
  for_each = toset(var.regions)
  enable   = true
  region   = each.key
}

resource "aws_guardduty_detector_feature" "enabled" {
  for_each = {
    for pair in setproduct(var.regions, [
      "S3_DATA_EVENTS",
      "EBS_MALWARE_PROTECTION",
      "RDS_LOGIN_EVENTS",
      "LAMBDA_NETWORK_LOGS",
      ]) : "${pair[0]}/${pair[1]}" => {
      region = pair[0]
      name   = pair[1]
    }
  }
  detector_id = aws_guardduty_detector.main[each.value.region].id
  name        = each.value.name
  status      = "ENABLED"
  region      = each.value.region
}

# GuardDuty creates /aws/guardduty/malware-scan-events on-demand with a 90-day default
# retention. We declare it explicitly so Terraform owns the retention setting (365 days
# for ISO 27001). Pre-creating is safe — GuardDuty reuses an existing log group.
resource "aws_cloudwatch_log_group" "malware_scan_events" {
  # checkov:skip=CKV_AWS_158: GuardDuty creates this service-owned log group without
  # a customer-managed KMS key (verified: kmsKeyId=null on GuardDuty-provisioned
  # groups). Attaching a CMK here would diverge from GuardDuty's own posture for
  # scan-metadata logs and introduce a key-policy dependency on the CloudWatch Logs
  # service principal. The log group remains encrypted at rest with AWS-owned keys.
  for_each          = toset(var.regions)
  name              = "/aws/guardduty/malware-scan-events"
  retention_in_days = var.malware_scan_events_retention_days
  region            = each.key
}

# Separate resource to workaround a provider bug
# https://github.com/hashicorp/terraform-provider-aws/issues/36400
resource "aws_guardduty_detector_feature" "runtime_monitoring" {
  for_each    = toset(var.regions)
  detector_id = aws_guardduty_detector.main[each.key].id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"
  region      = each.key
  additional_configuration {
    name   = "EKS_ADDON_MANAGEMENT"
    status = "DISABLED"
  }
  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "DISABLED"
  }
  additional_configuration {
    name   = "EC2_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  for_each    = toset(var.regions)
  name        = "GuardDutyFindings"
  description = "Capture GuardDuty findings"
  region      = each.key
  event_pattern = jsonencode(
    {
      "source" : ["aws.guardduty"],
      "detail-type" : ["GuardDuty Finding"]
    }
  )
}

resource "aws_sns_topic" "guardduty_notifications" {
  for_each          = toset(var.regions)
  name_prefix       = "guardduty-"
  kms_master_key_id = "alias/aws/sns"
  region            = each.key
}

resource "aws_sns_topic_subscription" "guardduty_emails" {
  for_each  = toset(var.regions)
  endpoint  = var.security_contact.email
  protocol  = "email"
  topic_arn = aws_sns_topic.guardduty_notifications[each.key].arn
  region    = each.key
}

resource "aws_cloudwatch_event_target" "guardduty_notify" {
  for_each = toset(var.regions)
  rule     = aws_cloudwatch_event_rule.guardduty_findings[each.key].name
  arn      = aws_sns_topic.guardduty_notifications[each.key].arn
  role_arn = aws_iam_role.guardduty.arn
  region   = each.key
}

data "aws_iam_policy_document" "guardduty_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["events.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "guardduty_permissions" {
  statement {
    actions   = ["sns:Publish"]
    resources = [for topic in aws_sns_topic.guardduty_notifications : topic.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_role" "guardduty" {
  name_prefix        = "guardduty-publish-"
  assume_role_policy = data.aws_iam_policy_document.guardduty_assume.json
}

resource "aws_iam_policy" "guardduty" {
  policy = data.aws_iam_policy_document.guardduty_permissions.json
}

resource "aws_iam_role_policy_attachment" "guardduty" {
  policy_arn = aws_iam_policy.guardduty.arn
  role       = aws_iam_role.guardduty.name
}
