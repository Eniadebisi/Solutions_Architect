output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_arn" {
  value = module.ecr.repository_arn
}

output "infra_ci_role_arn" {
  value = module.iam.infra_ci_role_arn
}

output "football_api_secret_arn" {
  value = module.secrets_global.football_api_secret_arn
}
