
output "github_actions_role_arn" {
  description = "Set this as the GitHub repository variable AWS_DEPLOY_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.github.arn
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  value = var.aws_region
}