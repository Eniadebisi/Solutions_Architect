provider "aws" {
  region  = "us-east-1"
  profile = "world-cup"
}

data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket  = "world-cup-tfstate"
    key     = "global/terraform.tfstate"
    region  = "us-east-1"
    profile = "world-cup"
  }
}

module "networking" {
  source = "../modules/networking"

  project_name        = var.project_name
  cluster_name        = var.cluster_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  eks_subnet_cidrs    = var.eks_subnet_cidrs
  rds_subnet_cidrs    = var.rds_subnet_cidrs
  container_port      = var.container_port
}

module "observability" {
  source = "../modules/observability"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
}

module "eks" {
  source = "../modules/eks"

  project_name    = var.project_name
  cluster_name    = var.cluster_name
  vpc_id          = module.networking.vpc_id
  eks_subnet_ids  = module.networking.eks_subnet_ids
  eks_nodes_sg_id = module.networking.eks_nodes_sg_id
}

module "rds" {
  source = "../modules/rds"

  project_name          = var.project_name
  rds_subnet_group_name = module.networking.rds_subnet_group_name
  rds_sg_id             = module.networking.rds_sg_id
}

module "secrets_platform" {
  source = "../modules/secrets-platform"

  project_name            = var.project_name
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_provider           = module.eks.oidc_provider
  db_secret_arn           = module.rds.db_instance_master_user_secret_arn
  football_api_secret_arn = data.terraform_remote_state.global.outputs.football_api_secret_arn
}
