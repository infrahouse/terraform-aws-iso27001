# GuardDuty

This module manages Amazon GuardDuty **per account** — it enables a detector and
its protection features in every region listed in [`regions`](configuration.md#regions).
In an AWS Organization you can instead manage GuardDuty **centrally** through a
delegated administrator. Both models are valid; this page explains the
difference and, most importantly, how to avoid configuration drift when an
organization uses both at once.

## Per-account model (module default)

When you deploy this module in an account, it manages, in each region:

- `aws_guardduty_detector` — the detector itself.
- Protection features — S3 data events, EBS malware protection, RDS login
  events, Lambda network logs.
- `RUNTIME_MONITORING` — with the agent auto-management sub-features
  (EC2 / EKS / Fargate).

It also manages two account-local resources that the centralized model does
**not** touch (see [below](#what-stays-per-account)):

- `aws_cloudwatch_log_group.malware_scan_events` — so retention can be set
  explicitly (see [`guardduty_log_retention_days`](configuration.md#guardduty_log_retention_days)).
- A findings → SNS email notification to the [`security_contact`](configuration.md#security_contact).

This model suits standalone accounts, or organizations that do **not** use a
GuardDuty delegated administrator.

### Tuning Runtime Monitoring agent management

GuardDuty Runtime Monitoring is billed **per vCPU-hour of monitored compute**.
The [`runtime_monitoring`](configuration.md#runtime_monitoring) variable controls
which compute types get the agent auto-deployed:

```hcl
runtime_monitoring = {
  enable_ec2_agent_management         = true   # default
  enable_eks_addon_management         = false  # default; true installs the GuardDuty add-on into EKS clusters
  enable_ecs_fargate_agent_management = false  # default; true injects an agent sidecar into Fargate tasks
}
```

!!! tip
    Enable a compute type only where you actually run it. Where you don't run
    EKS or Fargate, enabling its agent management deploys nothing and costs
    nothing — but `enable_eks_addon_management = true` and
    `enable_ecs_fargate_agent_management = true` are **not** no-ops where those
    workloads exist (they modify clusters / task execution).

## Centralized model (organization delegated administrator)

In an organization you can designate a delegated administrator and manage
GuardDuty for all member accounts from one place. This is configured with
AWS's organization resources, **outside this module**:

```hcl
# In the organization management account:
resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = "<delegated-admin-account-id>"
}

# In the delegated administrator account (per region):
resource "aws_guardduty_detector" "this" {
  enable = true
}

resource "aws_guardduty_organization_configuration" "this" {
  detector_id                      = aws_guardduty_detector.this.id
  auto_enable_organization_members = "ALL" # ALL | NEW | NONE
}

resource "aws_guardduty_organization_configuration_feature" "runtime" {
  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  auto_enable = "ALL"

  additional_configuration {
    name        = "EKS_ADDON_MANAGEMENT"
    auto_enable = "NONE" # ALL | NEW | NONE
  }
  additional_configuration {
    name        = "ECS_FARGATE_AGENT_MANAGEMENT"
    auto_enable = "ALL"
  }
  additional_configuration {
    name        = "EC2_AGENT_MANAGEMENT"
    auto_enable = "ALL"
  }
}
```

With `auto_enable_organization_members = "ALL"`, GuardDuty enables the detector
and the configured features in every member account automatically — including
accounts where this module is also deployed.

## Avoiding drift: one owner per setting

!!! warning "Do not manage GuardDuty features in two places"
    If GuardDuty is managed centrally **and** this module also manages the
    detector/features in a member account, you have **two declarative owners of
    the same settings**. Every `terraform plan` then shows drift — most often on
    `aws_guardduty_detector_feature.runtime_monitoring` flipping the EKS/Fargate
    agent-management flags back and forth.

Pick one owner:

=== "Per-account (module owns it)"

    Let this module own the detector and features. Set
    [`runtime_monitoring`](configuration.md#runtime_monitoring) to your intended
    values. Do **not** also assert these features via
    `aws_guardduty_organization_configuration_feature`.

=== "Centralized (delegated admin owns it)"

    Set [`create_guardduty_detector = false`](configuration.md#create_guardduty_detector)
    so the module stops managing the detector and its features — the
    organization auto-enable creates and owns the detector instead. The
    malware-scan log group and findings notification stay managed by the module.
    See [Migrating per-account → centralized](#migrating-per-account-centralized)
    for moving an account that previously managed the detector.

### What stays per-account

The malware-scan **log group** and the findings **notification** are not part of
the organization configuration — GuardDuty does not manage CloudWatch log-group
retention or SNS notifications for you. They remain useful in either model and
are independent of who owns the detector, so this module keeps managing them
regardless.

## Migrating per-account → centralized

!!! danger "Use `state rm`, do not destroy the detector"
    When you hand a member account's GuardDuty over to central management,
    Terraform will plan to **destroy** the detector and features this module
    previously managed. **Do not apply that destroy.** Destroying
    `aws_guardduty_detector` disables GuardDuty in the account and
    cascade-deletes attached resources such as `aws_guardduty_threatintelset`.
    Instead, remove them from this module's state and let the organization's
    auto-enable keep the live detector:

    ```bash
    terraform state rm 'module.<name>.aws_guardduty_detector.main["us-west-1"]'
    terraform state rm 'module.<name>.aws_guardduty_detector_feature.runtime_monitoring["us-west-1"]'
    # ... repeat per region / feature
    ```
