terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source       = "./modules/networking"
  aws_region   = var.aws_region
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  az_a         = "${var.aws_region}a"
  az_b         = "${var.aws_region}b"
}

module "storage" {
  source        = "./modules/storage"
  aws_region    = var.aws_region
  project_name  = var.project_name
  website_index = var.website_index
  website_error = var.website_error
}

module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  public_subnet_id  = module.networking.public_subnet_id
  private_subnet_id = module.networking.private_subnet_id
  public_sg_id      = module.networking.public_sg_id
  private_sg_id     = module.networking.private_sg_id
  instance_type     = var.instance_type
  key_name          = var.key_name
}

module "monitoring" {
  source              = "./modules/monitoring"
  project_name        = var.project_name
  aws_region          = var.aws_region
  public_instance_id  = module.compute.public_instance_id
  private_instance_id = module.compute.private_instance_id
  s3_bucket_name      = module.storage.bucket_name
  alarm_email         = var.alarm_email
}
