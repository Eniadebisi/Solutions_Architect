terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

variable "project_name"  { type = string }
variable "aws_region"          { type = string }
variable "website_index" { type = string }
variable "website_error" { type = string }
