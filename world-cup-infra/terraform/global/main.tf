provider "aws" {
  region  = "us-east-1"
  profile = "world-cup"
}

module "ecr" {
  source       = "../modules/ecr"
  project_name = var.project_name
}

module "iam" {
  source       = "../modules/iam"
  project_name = var.project_name
}

module "secrets_global" {
  source           = "../modules/secrets-global"
  project_name     = var.project_name
  football_api_key = var.football_api_key
  football_api_url = var.football_api_url
}
