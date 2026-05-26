variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for all resource names"
  type        = string
  default     = "static-site"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free tier)"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
}

variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default = "enioluwa.adebisi@techconsulting.tech"
}

variable "website_index" {
  description = "S3 static site index document"
  type        = string
  default     = "index.html"
}

variable "website_error" {
  description = "S3 static site error document"
  type        = string
  default     = "error.html"
}
