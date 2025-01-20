resource "aws_iam_account_password_policy" "this" {
    allow_users_to_change_password = true
    max_password_age               = 90
    minimum_password_length        = 20
    password_reuse_prevention      = 24
    require_lowercase_characters   = true
    require_numbers                = true
    require_symbols                = true
    require_uppercase_characters   = true
}
