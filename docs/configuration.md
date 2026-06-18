# Configuration

## Required Variables

### `regions`

List of AWS regions to configure regional ISO 27001 controls in. Regional
resources (EBS encryption, Access Analyzer, GuardDuty, default security groups)
are created in each listed region. Global resources (contacts, password policy,
S3 block, IAM roles) are created once regardless.

```hcl
regions = ["us-east-1", "us-west-2", "eu-west-1"]
```

### `primary_contact`

Primary contact information for the AWS account.

```hcl
primary_contact = {
  address_line_1     = "123 Any Street"
  address_line_2     = null          # optional
  address_line_3     = null          # optional
  city               = "Seattle"
  company_name       = "Example Corp"
  country_code       = "US"
  district_or_county = null          # optional
  full_name          = "John Smith"
  phone_number       = "+1234567890"
  postal_code        = "98101"
  state_or_region    = "WA"          # optional
  website_url        = null          # optional
}
```

### `security_contact`

Security contact for the AWS account. This email also receives GuardDuty
finding notifications via SNS.

```hcl
security_contact = {
  full_name    = "Security Team"
  title        = "Security Officer"
  email        = "security@example.com"
  phone_number = "+1234567890"
}
```

## Optional Variables

### `guardduty_log_retention_days`

Retention (in days) for the `/aws/guardduty/malware-scan-events` log group.
GuardDuty creates this log group on-demand with a 90-day default; this module
takes ownership of it so the retention can be set explicitly. Default: `365`
(ISO 27001 standard).

```hcl
guardduty_log_retention_days = 365
```

### `runtime_monitoring`

Controls which compute types get the GuardDuty Runtime Monitoring agent
auto-deployed. Billed per vCPU-hour of monitored compute. Defaults preserve the
historical behavior (EC2 on, EKS/Fargate off); enable EKS/Fargate only in
accounts that run those workloads. See
[GuardDuty: centralized vs per-account](guardduty.md) for guidance on avoiding
drift when an organization manages GuardDuty centrally.

```hcl
runtime_monitoring = {
  enable_ec2_agent_management         = true   # default
  enable_eks_addon_management         = false  # default; true installs the GuardDuty EKS add-on
  enable_ecs_fargate_agent_management = false  # default; true injects an agent sidecar into Fargate tasks
}
```

### `create_guardduty_detector`

Whether this module creates and manages the GuardDuty detector and its features
in the account. Default `true`. Set to `false` in member accounts where GuardDuty
is managed centrally by an organization delegated administrator — the organization
auto-enable creates and owns the detector, so the module must not. The
malware-scan log group and findings notification are managed regardless. See
[GuardDuty: centralized vs per-account](guardduty.md).

```hcl
create_guardduty_detector = false
```

## Security Controls Applied

| Control | Scope | Details |
|---------|-------|---------|
| Password policy | Account | 21 char min, all character types, 24 password memory |
| EBS encryption | Per region | Enabled by default |
| S3 public access block | Account | All four block settings enabled |
| IAM Access Analyzer | Per region | External access analyzer |
| GuardDuty | Per region | Detector + features enabled; runtime monitoring agent management configurable via `runtime_monitoring` (see [GuardDuty](guardduty.md)) |
| GuardDuty malware-scan log retention | Per region | 365-day retention on `/aws/guardduty/malware-scan-events` |
| Default security groups | Per region | Deny all ingress and egress |
| Vanta auditor role | Account | `vanta-auditor` role with SecurityAudit + Identity Store read; external ID from SSM |
| InfraHouseGovernance role | Account | Trusts management account root; logs + lambda read/tag actions |
| InfraHouseLogRetention role | Account | Trusts management account root (**deprecated**, removed in next major release) |
