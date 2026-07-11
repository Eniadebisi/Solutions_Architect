# VPC
output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

# Public (load balancer)
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "lb_sg_id" {
  value = aws_security_group.lb.id
}

# EKS
output "eks_subnet_ids" {
  value = aws_subnet.eks[*].id
}

output "eks_nodes_sg_id" {
  value = aws_security_group.eks_nodes.id
}

output "eks_route_table_id" {
  value = aws_route_table.eks.id
}

# RDS
output "rds_subnet_ids" {
  value = aws_subnet.rds[*].id
}

output "rds_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}
