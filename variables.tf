variable "notification_email" {
  description = "Email address to send GuardDuty notifications to."

}

variable "configure_password_policy" {
  description = "If true, the module will configure the password policy."
  type        = bool
  default     = false
}
