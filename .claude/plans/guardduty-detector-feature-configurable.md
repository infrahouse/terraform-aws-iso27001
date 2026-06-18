# GuardDuty Detector Features — Configurable + Cedable to Central

## Context

`guardduty.tf` hardcodes the `RUNTIME_MONITORING` sub-features:

```
EKS_ADDON_MANAGEMENT         = DISABLED
ECS_FARGATE_AGENT_MANAGEMENT = DISABLED
EC2_AGENT_MANAGEMENT         = ENABLED
```

When GuardDuty is managed centrally for an organization (a delegated
administrator with `aws_guardduty_organization_configuration*`, or the unified
Security Hub org configuration), those agent-management flags get enabled
org-wide. The module insists on the hardcoded values, so every consumer shows
perpetual drift on `aws_guardduty_detector_feature.runtime_monitoring[*]`.

Root cause: **two declarative owners of the same setting** — the per-account
module vs. the central org config. Fix is two parts: (1) make the flags
configurable so a consumer can express the intended value instead of a hardcoded
one, and (2) allow the module to cede detector/feature ownership entirely where
GuardDuty is centrally managed.

Runtime Monitoring is billed per vCPU-hour of monitored compute, so enabling a
compute type where you don't run it is a no-op (no cost), and the only real
decision is to match the value the central config asserts.

---

## Work Items

### 1. Make `runtime_monitoring` configurable (object variable) — DONE

Replace the hardcoded `additional_configuration` statuses with a variable;
defaults preserve historical behavior (EC2 on, EKS/Fargate off), so upgrading
the module without setting the variable changes nothing.

```
variable "runtime_monitoring" {
  type = object({
    ec2_agent_management         = optional(bool, true)
    eks_addon_management         = optional(bool, false)
    ecs_fargate_agent_management = optional(bool, false)
  })
  default = {}
}
```

Statuses in `aws_guardduty_detector_feature.runtime_monitoring` now derive from
the variable via a ternary. Document that `eks_addon_management=true` installs
the GuardDuty add-on into EKS clusters and `ecs_fargate_agent_management=true`
injects an agent sidecar into Fargate tasks — neither is a no-op where those
workloads exist. A consumer that runs Fargate sets
`runtime_monitoring = { ecs_fargate_agent_management = true }` and the module
asserts ENABLED, matching the central config and clearing the drift in place.

### 2. Add `manage_guardduty_detector` toggle (cede to central) — TODO

`guardduty.tf` does several things; only the detector + features collide with
central org management. Gate ONLY those:

- Gate with `for_each = var.manage_guardduty_detector ? toset(var.regions) : []`:
  - `aws_guardduty_detector.main`
  - `aws_guardduty_detector_feature.enabled`
  - `aws_guardduty_detector_feature.runtime_monitoring`
- KEEP UNCONDITIONAL (independent of the detector resource; central does NOT
  manage these):
  - `aws_cloudwatch_log_group.malware_scan_events` — retention-compliance
    control. The auto-created group defaults to 90d and fails the ISO 27001
    retention standard; the module pre-declares it at `guardduty_log_retention_days`.
    Keyed by name, no `detector_id` reference.
  - `aws_cloudwatch_event_rule.guardduty_findings` + SNS topic + subscription +
    target + IAM role/policy — findings notification. Event pattern is
    `source: aws.guardduty`; no detector reference.

```
variable "manage_guardduty_detector" {
  description = "Manage the GuardDuty detector and its features in this account. Set false in member accounts where the org delegated administrator manages GuardDuty centrally. The malware-scan log group and findings-notification resources are always managed regardless."
  type    = bool
  default = true
}
```

### 3. Direction: central GuardDuty (delegated administrator)

GuardDuty org management is fully Terraform-supported:

- In the **management account**: `aws_guardduty_organization_admin_account` ->
  the delegated-administrator account.
- In the **delegated-administrator account**, per region: `aws_guardduty_detector`
  + `aws_guardduty_organization_configuration`
  (`auto_enable_organization_members = "ALL"`) +
  `aws_guardduty_organization_configuration_feature` for `RUNTIME_MONITORING`
  with `additional_configuration` auto_enable per compute type. Set the
  deprecated `EKS_RUNTIME_MONITORING` feature to `NONE` to avoid a perpetual diff.

Once central owns features, member accounts set `manage_guardduty_detector=false`
and this module stops fighting the org config.

---

## State Migration — `state rm`, do NOT destroy

When flipping `manage_guardduty_detector = false` in a member account, Terraform
plans to DESTROY the now-unmanaged detector + features. Do not let it. Destroying
`aws_guardduty_detector` disables GuardDuty in the account and cascade-deletes
attached resources (e.g. any `aws_guardduty_threatintelset` on that detector).
Instead `terraform state rm` each detector/feature resource per region, e.g.:

```
terraform state rm 'module.<name>.aws_guardduty_detector.main["us-west-1"]'
terraform state rm 'module.<name>.aws_guardduty_detector_feature.runtime_monitoring["us-west-1"]'
# ... repeat per region / feature
```

The org auto-enable keeps the live detector running; `state rm` hands ownership
to central without a destroy.

---

## Deployment Order

1. Release module with #1 (+ #2 when ready); back-compat defaults mean no
   behavior change until consumers set values.
2. In consumers that run Fargate/EKS, set the matching `runtime_monitoring`
   values; apply -> drift clears in place (no destroy).
3. (Later) Stand up central GuardDuty in the delegated-administrator account and
   admin designation in the management account, then flip member accounts to
   `manage_guardduty_detector=false` with `state rm` per the migration note.
