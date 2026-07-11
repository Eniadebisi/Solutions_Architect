terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "world-cup-tfstate"
    key          = "platform/terraform.tfstate"
    region       = "us-east-1"
    profile      = "world-cup"
    encrypt      = true
    use_lockfile = true
  }
}
