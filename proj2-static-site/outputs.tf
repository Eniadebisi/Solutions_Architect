output "website_url" {
  description = "S3 static website URL"
  value       = module.storage.website_url
}

output "public_ec2_ip" {
  description = "Public IP of the public EC2 instance"
  value       = module.compute.public_instance_ip
}

output "public_ec2_dns" {
  description = "Public DNS of the public EC2 instance"
  value       = module.compute.public_instance_dns
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.dashboard_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}
