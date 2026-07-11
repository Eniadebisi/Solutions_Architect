# world-cup-infra

Infrastructure-as-Code for the world-cup project. Lives inside `Solutions_Architect/world-cup-infra/`.

## Repo layout

```
Solutions_Architect/
└── world-cup-infra/
    ├── README.md               ← this file
    ├── guide.md                ← step-by-step build guide (start here)
    ├── deploy-test.md          ← copy-paste deploy/test runbook
    ├── docs/
    │   ├── terraform-backend.md
    │   ├── vpc.md
    │   ├── eks.md
    │   ├── rds.md
    │   ├── secrets-manager.md
    │   ├── external-secrets-operator.md
    │   ├── argocd.md
    │   ├── github-actions.md
    │   └── security-scanning.md
    ├── terraform/
    │   ├── global/             ← persistent stack: apply once
    │   │   ├── main.tf         ← calls ecr, iam, secrets-global modules
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── backend.tf      ← key = "global/terraform.tfstate"
    │   ├── platform/           ← spinnable stack: destroy/recreate freely
    │   │   ├── main.tf         ← calls networking, observability, eks, rds, secrets-platform modules
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── backend.tf      ← key = "platform/terraform.tfstate"
    │   └── modules/            ← all resource definitions live here (no backend.tf)
    │       ├── networking/
    │       ├── observability/
    │       ├── eks/
    │       ├── rds/
    │       ├── ecr/
    │       ├── iam/
    │       ├── secrets-global/
    │       └── secrets-platform/
    ├── helm/
    │   └── world-cup/
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    │           ├── deployment.yaml
    │           ├── service.yaml
    │           ├── serviceaccount.yaml
    │           └── external-secret.yaml
    └── argocd/
        └── app.yaml
```

## Where to start

Read `guide.md`. It walks you through provisioning one resource at a time with a verification step after each.

## Separation of concerns

This repo only contains infrastructure. The application code lives in `world-cup-app`. The one coupling point is the Docker image tag: when the app pipeline pushes a new image to ECR, it opens a PR here updating `helm/world-cup/values.yaml` with the new SHA tag. ArgoCD detects the merge and syncs the cluster.

## Cost estimate

| Resource | Type | Est. monthly |
|---|---|---|
| EKS cluster | Control plane only | ~$72 |
| EC2 nodes | 2× t3.small spot | ~$8 |
| RDS | db.t3.micro single-AZ | ~$15 |
| ECR | < 1GB storage | ~$0.10 |
| VPC peering | Data transfer | ~$1 |
| Secrets Manager | 2 secrets | ~$0.80 |
| **Total** | | **~$97/month** |

Tear down EKS node group when not actively developing to cut costs to ~$15/month (RDS + control plane minimum).
