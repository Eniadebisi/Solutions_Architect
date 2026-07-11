# Terraform Backend — Remote State with S3 and DynamoDB

## What it does

The Terraform backend determines where state is stored and how it is locked. By default, state lives in a local `terraform.tfstate` file. That breaks the moment you run Terraform from two machines or from a CI pipeline — you end up with conflicting state files and corrupted infrastructure.

The S3 + DynamoDB backend solves both problems: S3 stores the state file remotely so any machine can access it, and DynamoDB provides a lock so only one `terraform apply` can run at a time.

## Key concepts

**State file** — a JSON file mapping every resource in your Terraform code to its real ID in AWS (`aws_vpc.main` → `vpc-0abc1234`). Terraform reads it before every plan to know what currently exists. Without it, Terraform has no memory.

**State locking** — before writing state, Terraform creates a lock record in DynamoDB. If another process is already running, the lock exists and the second run fails immediately with a clear error instead of silently corrupting state.

**State versioning** — S3 bucket versioning is enabled on the state bucket. If state is accidentally corrupted or deleted, you can restore a previous version from S3.

**Backend configuration** — a `backend` block in your Terraform code that tells Terraform where to read and write state. It is separate from your provider configuration.

## The chicken-and-egg problem

You cannot use Terraform to create the S3 bucket and DynamoDB table that Terraform needs to store its own state. You have to create these manually first, then configure the backend to use them.

Create them once using the AWS CLI:

```bash
# Create the S3 bucket
aws s3api create-bucket --bucket world-cup-tfstate --profile world-cup

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket world-cup-tfstate \
  --versioning-configuration Status=Enabled \
  --profile world-cup

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket world-cup-tfstate \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --profile world-cup

# Block all public access
aws s3api put-public-access-block \
  --bucket world-cup-tfstate \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --profile world-cup

# Create the DynamoDB lock table
aws dynamodb create-table \
  --table-name world-cup-tflock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --profile world-cup
```

## Directory structure

The Terraform code is split into three top-level directories, each with a different lifecycle:

```
terraform/
  modules/              ← ALL resource definitions live here (child modules, no backend.tf)
    vpc/                ← EKS VPC + RDS VPC resources
    eks/                ← EKS cluster + node group resources
    rds/                ← RDS instance + subnet group resources
    peering/            ← VPC peering connection + routes between EKS and RDS VPCs
    secrets-global/     ← football-api secret (persists independently of the cluster)
    secrets-platform/   ← ESO IAM role + VPC endpoint (lives and dies with the platform stack)
    ecr/                ← ECR repository
    iam/                ← GitHub Actions OIDC provider + role
    security-groups/    ← shared security group patterns
  global/               ← persistant resources
    backend.tf          ← key = "global/terraform.tfstate"
    main.tf             ← calls ecr iam secrets from modules
    outputs.tf
  platform/             ← spinnable stack
    backend.tf          ← key = "platform/terraform.tfstate"
    main.tf             ← calls vpc eks rds peering from modules
    outputs.tf
```

**modules/** holds all Terraform resource definitions — no `backend.tf`, no `terraform init`, never applied directly. Every resource lives here, even if only used once. This keeps a consistent rule: root modules contain no resource blocks, only module calls and backend config.

**global/** root modules call into `modules/` for resources that persist for the lifetime of the project. Destroying the EKS stack does not touch these. Apply once, leave running.

**platform/** root modules call into `modules/` for the EKS stack and its dependencies. These can all be destroyed overnight or between sessions to save cost, then recreated from scratch.

## Apply order

Apply `global/` first (once). Apply `platform/` each time you spin the stack up. Terraform resolves the internal module dependency order automatically from the `terraform_remote_state` data sources and module references inside `platform/main.tf`.

```bash
# Once — permanent resources
cd terraform/global && terraform init && terraform apply

# Each spin-up
cd terraform/platform && terraform init && terraform apply
```

Within `platform/`, Terraform will apply modules in the correct order: vpc → eks + rds (parallel) → peering → secrets.

## Separated modules pattern

Each root module directory (`global/ecr/`, `platform/vpc/`, etc.) has its own `backend.tf` pointing at the same S3 bucket but with a unique `key`. The `key` is the S3 path where that module's state is stored. You run `terraform init` and `terraform apply` inside each directory independently.

There are exactly two state files:

| Root module | key | Contains |
|---|---|---|
| global/ | `global/terraform.tfstate` | ECR, IAM, football-api secret |
| platform/ | `platform/terraform.tfstate` | VPC, EKS, RDS, peering, ESO IAM role + VPC endpoint |

## Backend configuration

There are exactly two `backend.tf` files — one per root module.

**terraform/global/backend.tf:**
```hcl
terraform {
  backend "s3" {
    bucket       = "world-cup-tfstate"
    key          = "global/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
    profile      = "world-cup"
  }
}
```

**terraform/platform/backend.tf:**
```hcl
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
    use_lockfile = true
    encrypt      = true
    profile      = "world-cup"
  }
}
```

`use_lockfile = true` uses S3-native locking. `dynamodb_table` is deprecated and removed — the DynamoDB table is no longer needed for locking.

## Referencing outputs across stacks

`platform/main.tf` reads outputs from `global/` state using a `terraform_remote_state` data source. This is the only cross-stack reference needed — `global/` must be applied before `platform/`.

```hcl
# In terraform/platform/main.tf
data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket  = "world-cup-tfstate"
    key     = "global/terraform.tfstate"
    region  = "us-east-1"
    profile = "world-cup"
  }
}

# Example: pass the ECR repo URL into the platform stack
module "eks" {
  source     = "../modules/eks"
  ecr_repo   = data.terraform_remote_state.global.outputs.ecr_repo_url
}
```

Within `platform/`, modules reference each other directly via module outputs — no remote state needed because they share the same state file:

```hcl
module "eks" {
  source             = "../modules/eks"
  eks_vpc_id         = module.vpc.eks_vpc_id
  private_subnet_ids = module.vpc.eks_private_subnet_ids
}
```

This is why defining outputs in each module matters — they are the contract between modules.

## Spinning down the platform stack

To destroy all platform resources (EKS, RDS, VPCs) and stop incurring cost:

```bash
cd terraform/platform && terraform destroy
```

Terraform resolves the destroy order automatically (reverse of apply). `global/` is untouched — ECR images, IAM roles, and the football-api secret persist. When you spin back up:

```bash
cd terraform/platform && terraform apply
```

## CLI commands

```bash
# Verify the backend bucket exists and is accessible
aws s3 ls s3://world-cup-tfstate --profile world-cup

# List all state files across modules
aws s3 ls s3://world-cup-tfstate --recursive --profile world-cup

# View raw state for a stack (useful for debugging)
aws s3 cp s3://world-cup-tfstate/platform/terraform.tfstate - \
  --profile world-cup | python3 -m json.tool | less

# List all resources tracked in state (from inside the module directory)
terraform state list

# Show details of a specific resource in state
terraform state show aws_vpc.main

# Pull current state to a local file (for inspection)
terraform state pull > local-state-backup.json

# Check if the DynamoDB lock table exists
aws dynamodb describe-table \
  --table-name world-cup-tflock \
  --profile world-cup \
  --query "Table.{Status:TableStatus,Keys:KeySchema}"

# View active locks (should be empty when no apply is running)
aws dynamodb scan \
  --table-name world-cup-tflock \
  --profile world-cup \
  --query "Items"
```

## Handling a stuck lock

If `terraform apply` is interrupted (Ctrl+C, network drop, CI job killed), the DynamoDB lock may not be released. The next run will fail with:

```
Error: Error acquiring the state lock
Lock ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Force-release it (only do this when you are certain no other apply is running):

```bash
terraform force-unlock <lock-id>
```

Or via the AWS CLI:

```bash
aws dynamodb delete-item \
  --table-name world-cup-tflock \
  --key '{"LockID": {"S": "world-cup-tfstate/platform/terraform.tfstate"}}' \
  --profile world-cup
```

## Moving or renaming resources

If you rename a resource in code (e.g. `aws_vpc.vpc` → `aws_vpc.main`), Terraform will try to destroy the old one and create a new one. To tell Terraform it is the same resource with a new name, use `state mv`:

```bash
terraform state mv aws_vpc.vpc aws_vpc.main
```

This updates state without touching AWS. Run `terraform plan` after to confirm zero diff.

## Importing existing resources

If a resource was created manually and you later want Terraform to manage it:

```bash
terraform import aws_s3_bucket.tfstate world-cup-tfstate
```

This reads the real resource from AWS and writes it into state. Then write the corresponding `resource` block in your code and run `plan` — it should show no changes if the code matches reality.

## Common issues

**`NoSuchBucket` on init** — the S3 bucket name in `backend.tf` does not match the bucket you created. Names are case-sensitive and must match exactly.

**`AccessDenied` on state read/write** — the AWS profile or IAM role being used does not have `s3:GetObject`, `s3:PutObject`, or `dynamodb:PutItem` on the backend resources. Check the IAM policy for your `world-cup` profile.

**`Error: Backend configuration changed`** — you changed something in the `backend` block. Run `terraform init -reconfigure` to re-initialize with the new config.

**State drift** — the real AWS resource was modified outside Terraform (via console or CLI). Run `terraform refresh` to update state to match reality, then `plan` to see if any code changes are needed.

**Output not found on `terraform_remote_state`** — the upstream module has not been applied yet, or its `outputs.tf` does not export the value you need. Apply the dependency first, then check its `outputs.tf`.

## Official docs

- [S3 backend configuration](https://developer.hashicorp.com/terraform/language/backend/s3)
- [State locking](https://developer.hashicorp.com/terraform/language/state/locking)
- [Remote state data source](https://developer.hashicorp.com/terraform/language/state/remote-state-data)
- [terraform state commands](https://developer.hashicorp.com/terraform/cli/commands/state)
- [Importing existing resources](https://developer.hashicorp.com/terraform/cli/import)
