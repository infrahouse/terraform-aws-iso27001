output "governance_role_name" {
  description = "Name of the InfraHouseGovernance cross-account IAM role."
  value       = aws_iam_role.InfraHouseGovernance.name
}

output "governance_role_arn" {
  description = "ARN of the InfraHouseGovernance cross-account IAM role."
  value       = aws_iam_role.InfraHouseGovernance.arn
}

output "log_retention_role_name" {
  description = <<-EOT
    Name of the deprecated InfraHouseLogRetention cross-account IAM role.
    Kept for migration to InfraHouseGovernance; will be removed in the next
    major release.
  EOT
  value       = aws_iam_role.InfraHouseLogRetention.name
}

output "log_retention_role_arn" {
  description = <<-EOT
    ARN of the deprecated InfraHouseLogRetention cross-account IAM role.
    Kept for migration to InfraHouseGovernance; will be removed in the next
    major release.
  EOT
  value       = aws_iam_role.InfraHouseLogRetention.arn
}
