# Vanta Role Automation — iso27001 Changes

## Context

The management-account module (`terraform-aws-org-governance`) now
distributes the Vanta external ID to all member accounts via a
CloudFormation StackSet (SERVICE_MANAGED). The SSM parameter
`/vanta/external_id` is guaranteed to exist in every member account
before iso27001 is deployed — auto-deployment fires on OU membership
during Control Tower enrollment, before any Terraform runs.

Full plan lives in:
`terraform-aws-org-governance/.claude/plans/vanta-role-automation.md`

---

## Work Items

### 1. InfraHouseGovernance role — NO CHANGE NEEDED

No SSM permissions required — the org-governance Lambda no longer
writes SSM params. StackSets handles distribution via the
Organizations service trust.

### 2. Vanta role external ID from SSM — DONE

Replace `var.vanta_external_id` with an SSM data source:

```hcl
data "aws_ssm_parameter" "vanta_external_id" {
  name = "/vanta/external_id"
}
```

Use `data.aws_ssm_parameter.vanta_external_id.value` in the trust
policy. Remove `var.vanta_external_id` entirely — no fallback needed
because the StackSet guarantees the parameter exists before iso27001
is ever deployed.

### 3. Identity Store permissions — SKIPPED (harmless, simpler)

The current `vanta_additional_permissions` policy includes Identity
Store actions. These only work in the management account (where IAM
Identity Center lives). In member accounts they are harmless no-ops
but add noise. Consider splitting or leave as-is (harmless, simpler).

---

## State Migration — delete-and-recreate

The vanta-auditor role exists in AWS managed by github-control.
No import needed — just delete from github-control first, then
iso27001 creates it fresh. Brief Vanta scan gap is acceptable.

## Deployment Order

1. **terraform-aws-org-governance** deploys StackSet — SSM params
   appear in all member accounts (already done).
2. **github-control** removes `vanta.tf` and applies — deletes
   the old role from all accounts.
3. **terraform-aws-iso27001** releases and applies — creates the
   role fresh with SSM-backed external ID.
