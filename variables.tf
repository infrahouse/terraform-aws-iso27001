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
