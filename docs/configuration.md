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

### `malware_scan_events_retention_days`

Retention (in days) for the `/aws/guardduty/malware-scan-events` log group.
GuardDuty creates this log group on-demand with a 90-day default; this module
takes ownership of it so the retention can be set explicitly. Default: `365`
(ISO 27001 standard).

```hcl
malware_scan_events_retention_days = 365
```

## Security Controls Applied

| Control | Scope | Details |
|---------|-------|---------|
| Password policy | Account | 21 char min, all character types, 24 password memory |
| EBS encryption | Per region | Enabled by default |
| S3 public access block | Account | All four block settings enabled |
| IAM Access Analyzer | Per region | External access analyzer |
| GuardDuty | Per region | All features enabled including runtime monitoring |
| GuardDuty malware-scan log retention | Per region | 365-day retention on `/aws/guardduty/malware-scan-events` |
| Default security groups | Per region | Deny all ingress and egress |
| InfraHouseLogRetention role | Account | Trusts management account root |
