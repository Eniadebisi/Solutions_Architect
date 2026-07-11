# GUIDE — Building world-cup-infra

## Prerequisites

- AWS CLI v2 — configured with a named profile (e.g. `world-cup`)
- Terraform >= 1.5
- kubectl
- helm >= 3
- An AWS account with sufficient IAM permissions (or role)
- A GitHub repo for `world-cup-infra`

Confirm your AWS identity before starting anything:

```bash
aws sts get-caller-identity --profile world-cup
```

---

## Step 1 — Terraform remote state backend

Bootstrap an S3 bucket for state (S3-native locking via `use_lockfile`, no DynamoDB table needed). This must exist before anything else — both root modules (`global/` and `platform/`) reference it.

See [`docs/terraform-backend.md`](docs/terraform-backend.md) for the CLI bootstrap commands, `backend.tf` configuration, and troubleshooting.

**Verify:**

```bash
aws s3 ls s3://world-cup-tfstate --profile world-cup
```

---

## Step 2 — Global stack (ECR, IAM, football-api secret)

Apply `terraform/global` once. It provisions resources that persist independently of the platform stack and are never torn down between sessions:

- `modules/ecr` — the ECR repository for the app image
- `modules/iam` — the GitHub Actions OIDC provider + CI role
- `modules/secrets-global` — the `world-cup/football-api` secret

```bash
cd terraform/global
cp terraform.tfvars.example terraform.tfvars   # fill in GitHub org/username
export TF_VAR_football_api_key="your-key-here" # never put secrets in .tfvars
terraform init
terraform plan
terraform apply
```

**Verify:**

```bash
aws ecr describe-repositories --repository-names world-cup --profile world-cup
aws secretsmanager get-secret-value --secret-id world-cup/football-api \
  --query SecretString --profile world-cup
```

---

## Step 3 — Platform stack (networking, EKS, RDS, ESO role)

Apply `terraform/platform`. This is the spinnable stack — everything here can be destroyed and recreated without touching `global/`. `platform/main.tf` calls, in dependency order:

- `modules/networking` — one VPC (`10.0.0.0/16`), public subnets (LB), private EKS subnets, private RDS subnets, security groups, VPC Flow Logs
- `modules/observability` — CloudWatch log groups / dashboards for the VPC
- `modules/eks` — EKS cluster + managed node group (2× `t3.small` spot, private subnets), OIDC provider for IRSA
- `modules/rds` — PostgreSQL 16 `db.t3.micro` instance in the RDS private subnets, master password managed by Secrets Manager
- `modules/secrets-platform` — IAM role for ESO to assume via IRSA, scoped to `GetSecretValue` on both secret ARNs

```bash
cd ../platform
terraform init
terraform plan
terraform apply    # EKS takes ~12 min, RDS ~5 min
terraform output   # save eso_role_arn, rds_endpoint, db_secret_arn for later steps
```

See [`docs/vpc.md`](docs/vpc.md), [`docs/eks.md`](docs/eks.md), [`docs/rds.md`](docs/rds.md), and [`docs/secrets-manager.md`](docs/secrets-manager.md) for architecture detail on each module.

**Verify:**

```bash
aws eks update-kubeconfig --name world-cup --region us-east-1 --profile world-cup
kubectl get nodes   # 2 nodes in Ready state

aws eks describe-cluster --name world-cup \
  --query "cluster.identity.oidc.issuer" --profile world-cup

aws rds describe-db-instances \
  --query "DBInstances[?DBInstanceIdentifier=='world-cup'].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}" \
  --profile world-cup
```

The OIDC issuer URL confirms IRSA is available. RDS status should be `available`.

---

## Step 4 — Install External Secrets Operator

Install ESO so it can sync secrets from AWS Secrets Manager into native Kubernetes `Secret` objects. Annotate the ESO service account with the `eso_role_arn` output from Step 3.

See [`docs/external-secrets-operator.md`](docs/external-secrets-operator.md) for the Helm install, `ClusterSecretStore`, and `ExternalSecret` manifests.

**Verify:**

```bash
kubectl get pods -n external-secrets
kubectl get clustersecretstore   # Ready: True
```

---

## Step 5 — Install ArgoCD

Install ArgoCD via Helm to bootstrap GitOps. After this, all application deploys happen through Git — you never run `kubectl apply` manually in production.

See [`docs/argocd.md`](docs/argocd.md) for the Helm install command, `Application` manifest, and GitHub deploy key setup.

**Verify:**

```bash
kubectl get pods -n argocd
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

Open `http://localhost:8080`. Get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## Step 6 — Patch values.yaml and deploy the app via ArgoCD

Before applying the ArgoCD app, update `helm/world-cup/values.yaml` with the real values from `terraform -chdir=terraform/platform output`: `esoRoleArn`, `db.host` (hostname from `rds_endpoint`), and `secrets.dbSecretArn`. Commit and push to `main` so ArgoCD can read it.

ArgoCD renders the Helm chart from `helm/world-cup/` and deploys the API Deployment, Service, ServiceAccount, and ExternalSecret. The app will only start cleanly if the ExternalSecret has synced, RDS is reachable, and an ECR image exists.

```bash
kubectl apply -f argocd/app.yaml
```

**Verify:**

```bash
kubectl get application -n argocd
kubectl get pods -n world-cup
kubectl port-forward svc/world-cup-api 8000:8000 -n world-cup
curl http://localhost:8000/health
```

---

## Step 7 — GitHub Actions pipeline

CI/CD pipeline for this repo: `.github/workflows/pr-checks.yml` (lint/test/SAST/plan on PRs) and `.github/workflows/terraform-apply.yml` (applies on merge to `main`). The app's own pipeline (in `world-cup-app`) builds, scans, and pushes to ECR, then opens a PR here updating `values.yaml`; ArgoCD detects the merge and syncs the cluster.

See [`docs/github-actions.md`](docs/github-actions.md) for workflow structure, required secrets, and OIDC keyless AWS auth. See [`docs/security-scanning.md`](docs/security-scanning.md) for the Snyk/SonarQube/Trivy setup referenced by those workflows.

**Verify:**

```bash
aws ecr list-images --repository-name world-cup \
  --query "imageIds[].imageTag" --profile world-cup
```

A tag matching the commit SHA should appear. Merge the infra PR and watch ArgoCD sync.

---

## Full runbook

For copy-pasteable, step-by-step commands covering this entire flow end-to-end (including registering the repo with ArgoCD and testing a full GitOps deploy cycle), see [`deploy-test.md`](deploy-test.md).

---

## Tear-down order

Work in reverse to avoid dependency errors. `global/` is left alone — it holds ECR images, the IAM/OIDC role, and the football-api secret, none of which need to be recreated between sessions.

1. `kubectl delete application world-cup -n argocd`
2. `helm uninstall argocd -n argocd`
3. `helm uninstall external-secrets -n external-secrets`
4. `cd terraform/platform && terraform destroy` — destroys RDS, EKS, and networking in one pass; Terraform resolves the internal order automatically
5. Empty the S3 state bucket only if you are decommissioning the project entirely — never while `global/` state still references it

Do not destroy the S3 backend bucket while any state files reference it. Do not run `terraform destroy` in `terraform/global` unless you intend to lose the ECR repository, CI OIDC role, and football-api secret permanently.
