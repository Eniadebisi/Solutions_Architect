# RDS — Relational Database Service

## What it does

RDS is a managed relational database service. AWS handles OS patching, database software updates, automated backups, and hardware replacement. You choose the engine (PostgreSQL in this project), instance size, and storage, and AWS does the rest.

The alternative is self-managing a database on EC2 — installing PostgreSQL, configuring WAL archiving, handling upgrades yourself. RDS trades some flexibility for significantly reduced operational burden.

## Key concepts

**DB instance** — a single database server. Has a compute class (`db.t3.micro`), storage type (gp3 SSD), and engine (PostgreSQL 16).

**DB subnet group** — tells RDS which subnets it is allowed to place the instance in. Must span at least 2 Availability Zones even for single-AZ deployments.

**Parameter group** — a collection of database engine settings (e.g. `max_connections`, `log_statement`). The default parameter group is fine for learning.

**Automated backups** — RDS takes a daily snapshot and retains transaction logs, enabling point-in-time recovery. Retention period set to 7 days in this project.

**Multi-AZ** — RDS maintains a synchronous standby replica in a different AZ. If the primary fails, AWS promotes the standby automatically (60-120 second failover). Costs double. Disabled in this project for cost.

**Single-AZ** — one instance, one AZ. If that AZ has an outage, the database is unavailable. Acceptable for a learning project.

**Endpoint** — the DNS hostname your application connects to. Format: `<identifier>.<region>.rds.amazonaws.com`. This never changes even if the underlying instance is replaced.

**`manage_master_user_password`** — when enabled, RDS generates the master password and stores it in AWS Secrets Manager. AWS rotates it automatically. This is the pattern used in this project — you never see the master password in Terraform state or code.

## RDS setup in this project

- Engine: PostgreSQL 16
- Instance class: `db.t3.micro`
- Storage: 20GB gp3
- AZ: single, us-east-1a
- Backups: 7-day retention, automated
- Public access: false
- Deletion protection: false (easier teardown when learning)
- Master password: managed by AWS Secrets Manager

## Terraform resources involved

- `aws_db_instance`
- `aws_db_subnet_group`
- `aws_db_parameter_group` (optional, use default)
- `aws_security_group` — inbound 5432 from EKS node SG only
- `random_password` — only if not using `manage_master_user_password`

Community module: `terraform-aws-modules/rds/aws`

## Terraform setup

Module in `terraform/platform/rds/`. Calls the reusable module at `terraform/modules/rds/`. Uses `terraform-aws-modules/rds/aws`:

```hcl
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier        = "world-cup"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "world-cup"
  username = "world-cup"

  manage_master_user_password = true   # AWS stores credential in Secrets Manager

  db_subnet_group_name   = data.terraform_remote_state.vpc.outputs.rds_db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  deletion_protection     = false
  multi_az                = false
  publicly_accessible     = false
  skip_final_snapshot     = true
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "world-cup-tfstate"
    key     = "platform/vpc/terraform.tfstate"
    region  = "us-east-1"
    profile = "world-cup"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "world-cup-tfstate"
    key     = "platform/eks/terraform.tfstate"
    region  = "us-east-1"
    profile = "world-cup"
  }
}

# Security group — inbound 5432 from EKS node group SG only
resource "aws_security_group" "rds" {
  name   = "world-cup-rds-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.rds_vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.eks.outputs.node_security_group_id]
  }
}
```

## CLI commands

```bash
# List all RDS instances
aws rds describe-db-instances \
  --query "DBInstances[].{Id:DBInstanceIdentifier,Status:DBInstanceStatus,Class:DBInstanceClass,Engine:Engine,Endpoint:Endpoint.Address}" \
  --profile world-cup

# Describe a specific instance
aws rds describe-db-instances \
  --db-instance-identifier world-cup \
  --profile world-cup

# Get the endpoint hostname
aws rds describe-db-instances \
  --db-instance-identifier world-cup \
  --query "DBInstances[0].Endpoint.Address" \
  --profile world-cup

# List automated backups
aws rds describe-db-snapshots \
  --db-instance-identifier world-cup \
  --snapshot-type automated \
  --profile world-cup

# List manual snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier world-cup \
  --snapshot-type manual \
  --profile world-cup

# Create a manual snapshot before risky changes
aws rds create-db-snapshot \
  --db-instance-identifier world-cup \
  --db-snapshot-identifier world-cup-before-migration \
  --profile world-cup

# Reboot the instance (applies pending parameter changes)
aws rds reboot-db-instance \
  --db-instance-identifier world-cup \
  --profile world-cup

# Stop instance to save costs (only works for non-prod, max 7 days before auto-restart)
aws rds stop-db-instance \
  --db-instance-identifier world-cup \
  --profile world-cup

# Start instance after stopping
aws rds start-db-instance \
  --db-instance-identifier world-cup \
  --profile world-cup

# Check if a parameter change requires a reboot
aws rds describe-db-instances \
  --db-instance-identifier world-cup \
  --query "DBInstances[0].PendingModifiedValues" \
  --profile world-cup
```

## Connecting from inside the cluster

The RDS endpoint is only reachable from within the RDS VPC (or via VPC peering from the EKS VPC). You cannot connect directly from your laptop unless you set up a bastion host or SSM port forwarding.

```bash
# Port-forward from cluster to RDS via a debug pod (test connectivity)
kubectl run pg-client --image=postgres:16 --rm -it --restart=Never \
  -n world-cup \
  --env="PGPASSWORD=<password>" \
  -- psql -h <rds-endpoint> -U world-cup -d world-cup -c "\l"

# Run Alembic migrations from inside the cluster
kubectl run alembic --image=<your-ecr-image> --rm -it --restart=Never \
  -n world-cup \
  --env-from=secret/world-cup-db-secret \
  -- alembic upgrade head
```

## Running Alembic migrations safely

1. Take a manual RDS snapshot first (see CLI commands above)
2. Run the migration in a one-off pod (as above) or as a Kubernetes `Job`
3. Verify with `alembic history` and `alembic current`
4. Roll back with `alembic downgrade -1` if something goes wrong

```bash
# Check current migration version
alembic current

# Show migration history
alembic history --verbose

# Rollback one migration
alembic downgrade -1
```

## Common issues

**Cannot connect from EKS pod**: Check in order — VPC peering active, route tables have correct routes, RDS security group allows 5432 from EKS node security group, the pod is using the correct hostname from the K8s secret.

**`FATAL: password authentication failed`**: The Secrets Manager secret may be stale. ESO syncs on a schedule — force a resync: `kubectl annotate externalsecret world-cup-db-secret force-sync=$(date +%s) -n world-cup`.

**`max_connections` exceeded**: `db.t3.micro` default is 86 connections. SQLAlchemy connection pool defaults may be too high for this instance size. Set `pool_size=5, max_overflow=5` in your SQLAlchemy engine config.

## Official docs

- [RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [DB subnet groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html)
- [Managed master credentials](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-secrets-manager.html)
- [Parameter groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html)
