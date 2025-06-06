resource "aws_iam_account_password_policy" "strict" {
  count                          = data.aws_region.current.name == "us-east-1" ? 1 : 0
  minimum_password_length        = 21
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  # maximum number of 24 previous passwords that can't be repeated.
  password_reuse_prevention = 24
}
