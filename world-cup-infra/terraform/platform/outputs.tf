output "vpc_id" {
  value = module.networking.vpc_id
}

output "vpc_cidr" {
  value = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "eks_subnet_ids" {
  value = module.networking.eks_subnet_ids
}

output "rds_subnet_ids" {
  value = module.networking.rds_subnet_ids
}

output "rds_subnet_group_name" {
  value = module.networking.rds_subnet_group_name
}

output "lb_sg_id" {
  value = module.networking.lb_sg_id
}

output "eks_nodes_sg_id" {
  value = module.networking.eks_nodes_sg_id
}

output "rds_sg_id" {
  value = module.networking.rds_sg_id
}

output "eks_route_table_id" {
  value = module.networking.eks_route_table_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  value = module.eks.oidc_provider
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  value = module.rds.db_instance_master_user_secret_arn
}

output "eso_role_arn" {
  value = module.secrets_platform.eso_role_arn
}
