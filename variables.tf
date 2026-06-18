variable "regions" {
  description = "List of AWS regions to configure regional ISO 27001 controls in."
  type        = list(string)
}

variable "primary_contact" {
  description = "Primary contact for the account."
  type = object(
    {
      address_line_1     = string
      address_line_2     = optional(string, null)
      address_line_3     = optional(string, null)
      city               = string
      company_name       = string
      country_code       = string
      district_or_county = optional(string, null)
      full_name          = string
      phone_number       = string
      postal_code        = string
      state_or_region    = optional(string, null)
      website_url        = optional(string, null)
    }
  )
}

variable "security_contact" {
  description = "Security contact for the account."
  type = object(
    {
      full_name    = string
      phone_number = string
      title        = string
      email        = string
    }
  )
}

variable "capacity_dashboard_enabled" {
  description = <<-EOT
    Create a CloudWatch capacity-monitoring dashboard in each region.
    The dashboard auto-discovers EC2/ASG, RDS, ALB, Lambda, and SQS
    resources and displays the metrics checked by Vanta CAP-7
    (ISO 27001:2022 A.8.6).
  EOT
  type        = bool
  default     = true
}

variable "capacity_dashboard_name_prefix" {
  description = <<-EOT
    Name prefix for the per-region CloudWatch capacity dashboard.
    The region is appended automatically, e.g. "capacity-monitoring-us-west-1".
  EOT
  type        = string
  default     = "capacity-monitoring"
}

variable "guardduty_log_retention_days" {
  description = <<-EOT
    Retention (in days) applied to GuardDuty-owned CloudWatch log groups managed
    by this module (currently /aws/guardduty/malware-scan-events). Default 365
    satisfies the ISO 27001 retention standard. Must be a CloudWatch-Logs-supported
    value.
  EOT
  type        = number
  default     = 365

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.guardduty_log_retention_days
    )
    error_message = <<-EOT
      guardduty_log_retention_days must be one of the CloudWatch Logs-supported values
      (0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192,
      2557, 2922, 3288, 3653). Got: ${var.guardduty_log_retention_days}.
    EOT
  }
}

variable "runtime_monitoring" {
  description = <<-EOT
    GuardDuty Runtime Monitoring agent auto-management per compute type. The
    GuardDuty agent is billed per vCPU-hour of monitored compute, so only enable
    a compute type where you actually run it. Defaults preserve historical
    behavior (EC2 on, EKS/Fargate off).

    Note: enable_eks_addon_management=true installs the GuardDuty add-on into EKS
    clusters, and enable_ecs_fargate_agent_management=true injects an agent sidecar
    into Fargate tasks. Neither is a no-op where those workloads exist.
  EOT
  type = object({
    enable_ec2_agent_management         = optional(bool, true)
    enable_eks_addon_management         = optional(bool, false)
    enable_ecs_fargate_agent_management = optional(bool, false)
  })
  default = {}
}

variable "create_guardduty_detector" {
  description = <<-EOT
    Create and manage the GuardDuty detector and its features in this account. Set
    to false in member accounts where GuardDuty is managed centrally by an
    organization delegated administrator (the organization auto-enable creates and
    owns the detector). The malware-scan log group and findings-notification
    resources are managed regardless of this setting.
  EOT
  type        = bool
  default     = true
}
