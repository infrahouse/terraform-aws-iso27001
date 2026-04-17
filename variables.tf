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

variable "malware_scan_events_retention_days" {
  description = "Retention (in days) for the /aws/guardduty/malware-scan-events log group."
  type        = number
  default     = 365
}
