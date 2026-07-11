output "infra_ci_role_arn" {
  value = data.aws_iam_role.main.arn
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}
