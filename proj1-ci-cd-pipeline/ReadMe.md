This repository will be used to track learnings on projects. Project that will be used for actual implementation is dependent per project.

# Project 1 - Reusable CI/CD Pipeline Framework
Build a reusable multi-environment CI/CD framework using GitHub Actions, Docker, and AWS.

## Tools & Technologies

| Tool | Purpose |
|------|---------|
| **GitHub Actions** | CI/CD pipeline orchestration |
| **Docker** | Containerizing the application |
| **AWS ECR** | Private Docker image registry |
| **AWS ECS (Fargate)** | Serverless container runtime |
| **AWS IAM** | Permissions and role-based access |
| **AWS CloudWatch** | Container logs and crash alarms |
| **AWS VPC** | Network isolation for ECS tasks |
| **AWS S3** | Terraform remote state storage |
| **AWS DynamoDB** | Terraform state lock (prevents concurrent apply conflicts) |
| **Terraform** | Infrastructure as Code — provisions all AWS resources |

---

## Architecture Overview

```
GitHub Repo (impl)
    │  push to dev / qa / main
    ▼
GitHub Actions
    ├── Build Docker image
    ├── Push to ECR  ──────────────────► AWS ECR
    │                                    (image registry)
    └── Deploy to ECS ─────────────────► AWS ECS Fargate
                                         ├── dev cluster
                                         ├── qa cluster  (manual promote)
                                         └── prod cluster (approval gate)
                                              │
                                         CloudWatch Logs
                                         CloudWatch Alarms
```

## Features

1. Build pipeline
2. Docker image creation
3. Push to ECR
4. Automated deployment
5. Environment promotion: dev → qa → prod
6. Rollback support

---

## Pipeline Flow


### Trigger to Deploy (full journey)

```
1. Developer cuts a feature branch off dev
   git checkout -b feature/my-change dev
        │
2. Work is done, PR opened → dev branch
   - Code review happens here
        │
3. PR merged into dev branch
   build.yml triggers
   - Checks out code
   - Authenticates to AWS via OIDC (no static keys)
   - Builds Docker image
   - Tags image as dev-<git-sha>
   - Pushes to ECR
        │
4. deploy-dev.yml triggers automatically
   - Downloads current ECS task definition
   - Swaps image tag to the new dev-<git-sha>
   - Registers new task definition revision
   - Updates ECS dev service
   - Waits for service stability
   - ECS circuit breaker auto-rolls back if deploy fails
        │
5. Tested in dev → PR opened: dev → qa branch
   - Merge triggers deploy-qa.yml automatically
   - Same steps as dev but targets qa cluster
   - Uses same image SHA (no rebuild)
        │
6. Tested in qa → PR opened: qa → main branch
   - GitHub Environment protection rule pauses workflow
   - Required reviewer approves in GitHub UI
   - Deploys to prod cluster
   - Zero-downtime: new task starts before old one stops
```

### Branch → Environment Mapping

```
feature/* ──► dev ──► qa ──► main
                │      │       │
              dev     qa     prod
             cluster cluster cluster
```
```

Two things changed: step 1 now starts from a feature branch off `dev`, steps 4/5 are now auto-triggered by branch merges rather than manual triggers, and the branch mapping diagram makes the promotion path explicit.

### Rollback Flow

```
Developer triggers rollback.yml in GitHub Actions
    │
    ├── Specify environment (dev / qa / prod)
    └── Optionally specify a task definition revision number
            │
            ▼
    If no revision given → automatically targets revision N-1
            │
            ▼
    aws ecs update-service called with previous task definition
            │
            ▼
    ECS drains current tasks and starts previous revision
```

---

## Order of Setup

### Prerequisites (one-time)
1. Install Terraform
2. Verify AWS CLI is configured (`aws sts get-caller-identity`)
3. Create S3 bucket for Terraform state
4. Create DynamoDB table for Terraform state locking

### Infrastructure
5. Clone this repo, place `main.tf` under `projects/cicd-framework/`
6. Create `terraform.tfvars` with your `github_org` and `github_repo`
7. Fix backend block in `main.tf` with your bucket/table names
8. Run `terraform init` → `terraform plan` → `terraform apply`
9. Save the outputs (ECR URL, IAM role ARN, cluster names)

### GitHub Setup
10. Add 3 secrets to implementation repo (`AWS_ROLE_ARN`, `AWS_REGION`, `ECR_REPOSITORY`)
11. Create `dev`, `qa`, `prod` GitHub Environments (add approval gate on prod)

### Implementation Repo
12. Add `.github/workflows/` files (`build.yml`, `_deploy.yml`, `deploy-dev.yml`, `deploy-qa.yml`, `deploy-prod.yml`, `rollback.yml`)
13. Add `Dockerfile` with a working health check
14. Push to dev and verify pipeline runs in Actions tab

### Verification
15. Confirm image appears in ECR
16. Confirm ECS dev service is running (`runningCount = desiredCount`)
17. Confirm logs appear in CloudWatch
18. Test manual rollback workflow

---

## Key Design Decisions & Considerations

- Keyless AWS Authentication (OIDC)
- Fargate Spot for Dev/QA
- ECS Circuit Breaker
- One ECR Repo, Environment Tags
A single ECR repository is shared across all environments. The environment is encoded in the
image tag (`dev-abc1234`, `qa-abc1234`, `prod-abc1234`). This means the exact same image
artifact is promoted through environments — no rebuilds between dev and prod.
- Terraform Owns Infrastructure, CI/CD Owns Deployments

---

## Cost Estimate

| Resource | Dev/QA | Prod | Notes |
|----------|--------|------|-------|
| ECS Fargate Spot | ~$5/mo | — | Dev + QA combined |
| ECS Fargate | — | ~$15/mo | 1 task, 0.5 vCPU / 1GB |
| ECR storage | ~$1/mo | shared | Lifecycle policy auto-expires old images |
| CloudWatch Logs | ~$1/mo | ~$2/mo | 7-day retention dev, 30-day prod |
| S3 + DynamoDB | <$1/mo | shared | Terraform state only |
| **Total** | **~$7/mo** | **~$17/mo** | No NAT Gateway saves ~$32/mo |

---

## Deliverables

- [ ] GitHub Actions workflow
- [ ] Reusable deployment templates
- [ ] Parameterized pipeline

---

## Reusable Component

This framework is designed as a drop-in CI/CD solution. To reuse it for a new project:

1. Copy the `.github/workflows/` folder into the new repo
2. Update the `project_name` and `app_name` variables in `main.tf`
3. Swap the `Dockerfile` for the new app
4. Run `terraform apply` to provision fresh AWS resources
