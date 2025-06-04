module "guardduty" {
  source              = "registry.infrahouse.com/infrahouse/guardduty-configuration/aws"
  version             = "0.2.1"
  notifications_email = var.notification_email
}
