module "guardduty" {
  source              = "registry.infrahouse.com/infrahouse/guardduty-configuration/aws"
  version             = "0.3.0"
  notifications_email = var.security_contact.email
}
