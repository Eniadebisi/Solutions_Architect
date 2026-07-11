module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.project_name

  engine            = "postgres"
  engine_version    = "16"
  family            = "postgres16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = replace(var.project_name, "-", "_")
  username = replace(var.project_name, "-", "_")

  manage_master_user_password = true

  db_subnet_group_name   = var.rds_subnet_group_name
  vpc_security_group_ids = [var.rds_sg_id]

  backup_retention_period = 7
  deletion_protection     = false
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true

  tags = {
    Project = var.project_name
  }
}
