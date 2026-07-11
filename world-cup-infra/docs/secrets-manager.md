# Secrets Manager

## What it does

AWS Secrets Manager stores, retrieves, and rotates secrets (passwords, API keys, connection strings). It replaces storing secrets in environment variables baked into images, config files committed to Git, or SSM Parameter Store (which lacks automatic rotation).

The key difference from SSM Parameter Store: Secrets Manager supports automatic rotation via Lambda functions. Parameter Store is simpler and cheaper for static values but does not rotate automatically.

## Key concepts

**Secret** — a key-value pair or a JSON document stored encrypted at rest using KMS. Has an ARN, a name, and versioning.

**Secret version** — every time a secret value changes, a new version is created. The current version has the staging label `AWSCURRENT`. Previous versions are accessible by their version ID for rollback.

**Rotation** — Secrets Manager can automatically rotate a secret on a schedule by calling a Lambda function. For RDS managed passwords, AWS handles the Lambda automatically when you enable `manage_master_user_password` on the RDS instance.

**Resource policy** — an IAM policy attached directly to the secret that controls who can access it. Used alongside identity-based policies (IAM roles).

**KMS encryption** — secrets are encrypted with AWS KMS. The default key (`aws/secretsmanager`) is free. A customer-managed key gives more control but costs $1/month.

**VPC endpoint** — Secrets Manager is a regional AWS service with a public HTTPS endpoint. To access it from private subnets without internet access, you create a VPC Interface Endpoint. Traffic routes over the AWS private network. This is the pattern in this project (no NAT Gateway).

## Secrets in this project

| Secret name | Contents | Who accesses it |
|---|---|---|
| `world-cup/db` | `host`, `port`, `username`, `password`, `dbname` | ESO (via IRSA) → K8s secret → app pods |
| `world-cup/football-api` | `FOOTBALL_API_KEY`, `FOOTBALL_API_URL` | ESO (via IRSA) → K8s secret → app pods |

The `world-cup/db` secret is created and managed by RDS when `manage_master_user_password = true`. The `world-cup/football-api` secret is created by Terraform and updated manually when the API key changes.

## IRSA + ESO access flow

1. Terraform creates an IAM role (`world-cup-eso-role`) with a trust policy allowing the EKS OIDC provider to assume it
2. The trust policy restricts assumption to the ESO service account in the `external-secrets` namespace
3. The IAM role has an inline policy: `secretsmanager:GetSecretValue` on both secret ARNs
4. ESO's Kubernetes service account is annotated: `eks.amazonaws.com/role-arn: arn:aws:iam::<account>:role/world-cup-eso-role`
5. When ESO calls Secrets Manager, EKS injects a web identity token into the pod, and AWS STS exchanges it for temporary credentials scoped to the IAM role

No access keys. No credentials stored anywhere in the cluster.

## Terraform resources involved

- `aws_secretsmanager_secret`
- `aws_secretsmanager_secret_version`
- `aws_iam_role` (ESO role with OIDC trust policy)
- `aws_iam_policy` (GetSecretValue)
- `aws_iam_role_policy_attachment`
- `aws_vpc_endpoint` (interface endpoint for Secrets Manager)
- `aws_security_group` (for the VPC endpoint)

## Terraform setup

Module in `terraform/platform/secrets/`. Creates the football API secret, the ESO IAM role, and its policy. Reads outputs from `platform/eks` (OIDC provider ARN) and `platform/rds` (DB secret ARN):

```hcl
# Football API secret (DB secret is created automatically by RDS)
resource "aws_secretsmanager_secret" "football_api" {
  name = "world-cup/football-api"
}

resource "aws_secretsmanager_secret_version" "football_api" {
  secret_id = aws_secretsmanager_secret.football_api.id
  secret_string = jsonencode({
    FOOTBALL_API_KEY = var.football_api_key
    FOOTBALL_API_URL = var.football_api_url
  })
}

# IAM policy — GetSecretValue on both secrets
resource "aws_iam_policy" "eso_secrets" {
  name = "world-cup-eso-secrets"

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "world-cup-tfstate"
    key     = "platform/eks/terraform.tfstate"
    region  = "us-east-1"
    profile = "world-cup"
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket  = "world-cup-tfstate"
    key     = "platform/rds/terraform.tfstate"
    region  = "us-east-1"
    profile = "world-cup"
  }
}

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = [
        data.terraform_remote_state.rds.outputs.db_secret_arn,
        aws_secretsmanager_secret.football_api.arn,
      ]
    }]
  })
}

# IAM role — trusted by EKS OIDC provider, assumed by ESO service account
resource "aws_iam_role" "eso" {
  name = "world-cup-eso-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.terraform_remote_state.eks.outputs.oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub" =
            "system:serviceaccount:external-secrets:external-secrets"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eso_secrets" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso_secrets.arn
}
```

## CLI commands

```bash
# List all secrets
aws secretsmanager list-secrets \
  --query "SecretList[].{Name:Name,ARN:ARN}" \
  --profile world-cup

# Get the current secret value (decrypted)
aws secretsmanager get-secret-value \
  --secret-id world-cup/db \
  --query SecretString \
  --profile world-cup

# Get a specific version of a secret
aws secretsmanager get-secret-value \
  --secret-id world-cup/db \
  --version-stage AWSCURRENT \
  --profile world-cup

# Update the football API key
aws secretsmanager put-secret-value \
  --secret-id world-cup/football-api \
  --secret-string '{"FOOTBALL_API_KEY":"new-key","FOOTBALL_API_URL":"https://..."}' \
  --profile world-cup

# List all versions of a secret
aws secretsmanager list-secret-version-ids \
  --secret-id world-cup/db \
  --profile world-cup

# Describe a secret (metadata, rotation config, ARN)
aws secretsmanager describe-secret \
  --secret-id world-cup/db \
  --profile world-cup

# Manually trigger rotation (if rotation is configured)
aws secretsmanager rotate-secret \
  --secret-id world-cup/db \
  --profile world-cup

# Tag a secret
aws secretsmanager tag-resource \
  --secret-id world-cup/football-api \
  --tags Key=project,Value=world-cup Key=env,Value=dev \
  --profile world-cup

# Delete a secret (with 7-day recovery window)
aws secretsmanager delete-secret \
  --secret-id world-cup/football-api \
  --recovery-window-in-days 7 \
  --profile world-cup

# Delete immediately with no recovery (use with caution)
aws secretsmanager delete-secret \
  --secret-id world-cup/football-api \
  --force-delete-without-recovery \
  --profile world-cup
```

## Forcing ESO to re-sync after a secret update

When you update a secret value in Secrets Manager, ESO does not immediately pick it up. ESO syncs on a schedule defined in the `ExternalSecret` manifest (`refreshInterval`). To force an immediate sync:

```bash
kubectl annotate externalsecret world-cup-db-secret \
  force-sync=$(date +%s) \
  --overwrite \
  -n world-cup
```

Then verify the K8s secret was updated:

```bash
kubectl get secret world-cup-db-secret -n world-cup \
  -o jsonpath="{.data.host}" | base64 -d
```

## Common issues

**`AccessDeniedException` in ESO logs** — the IAM role does not have `GetSecretValue` on the specific secret ARN, or the trust policy is wrong. Check:

```bash
# Simulate the IAM permission check
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::<account>:role/world-cup-eso-role \
  --action-names secretsmanager:GetSecretValue \
  --resource-arns arn:aws:secretsmanager:us-east-1:<account>:secret:world-cup/db \
  --profile world-cup
```

**`ResourceNotFoundException`** — the secret name in the ExternalSecret manifest does not match the name in Secrets Manager. Names are case-sensitive.

**Secret not updating in pod** — the K8s secret was updated by ESO but the pod was not restarted. Kubernetes does not automatically restart pods when secrets change. Force a restart: `kubectl rollout restart deployment/world-cup-api -n world-cup`.

## Official docs

- [Secrets Manager overview](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)
- [Managing RDS credentials](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_how-services-use-secrets_RDS.html)
- [VPC endpoint for Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/vpc-endpoint-overview.html)
- [IRSA deep dive](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)
