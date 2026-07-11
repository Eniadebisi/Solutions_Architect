# Deploy & Test Runbook

Step-by-step commands to deploy the full world-cup stack and verify it is working.
Run each command individually. Read the comment above it before running.


## 1. Deploy global resources (ECR, IAM, football-api secret)

```bash
cd terraform/global
```

```bash
# Copy the example vars file and fill in your GitHub org/username
cp terraform.tfvars.example terraform.tfvars
```

```bash
# Set the football API key as an env var — never put secrets in .tfvars
export TF_VAR_football_api_key="your-key-here"
```

```bash
# Download providers and community modules
terraform init
```

```bash
# Preview what will be created — ECR repo, GitHub Actions OIDC role, football-api secret
terraform plan
```

```bash
# Create the resources
terraform apply
```


## 2. Deploy the platform stack (VPC, EKS, RDS, ESO role)

```bash
cd ../platform
```

```bash
# Download providers and community modules
terraform init
```

```bash
# Preview — VPC/subnets, EKS cluster + nodes, RDS instance, ESO IAM role
terraform plan
```

```bash
# Create the resources — EKS takes ~12 minutes, RDS ~5 minutes
terraform apply
```

```bash
# Save outputs you will need in later steps
terraform output
```


## 3. Connect kubectl to the cluster

```bash
# Writes a new context to ~/.kube/config pointing at the world-cup EKS cluster
aws eks update-kubeconfig --name world-cup --region us-east-1 --profile world-cup
```

```bash
# Verify the cluster is reachable
kubectl cluster-info
```

```bash
# Verify nodes are Ready — should show 2 nodes in Ready state
kubectl get nodes -o wide
```

```bash
# Verify the OIDC provider exists — IRSA won't work without this
aws eks describe-cluster \
  --name world-cup \
  --query "cluster.identity.oidc.issuer" \
  --profile world-cup
```


## 4. Install External Secrets Operator (ESO)

```bash
# Add the ESO Helm repo
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
```

```bash
# Install ESO into its own namespace — installs the CRDs and controller
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true
```

```bash
# Wait until the ESO controller pod is Running
kubectl get pods -n external-secrets
```

```bash
# Confirm the ExternalSecret CRD exists — ArgoCD needs this before syncing
kubectl get crd externalsecrets.external-secrets.io
```


## 5. Install ArgoCD

```bash
# Add the ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

```bash
# Install ArgoCD — ClusterIP service, insecure mode (no TLS, we use port-forward)
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=ClusterIP \
  --set "configs.params.server\.insecure=true"
```

```bash
# Wait until all ArgoCD pods are Running (takes ~60s)
kubectl get pods -n argocd
```

```bash
# Get the initial admin password
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

```bash
# Open the ArgoCD UI in your browser — runs in foreground, Ctrl+C to stop
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Then open http://localhost:8080  (username: admin, password: from step above)
```


## 6. Patch values.yaml with your terraform outputs

Before applying the ArgoCD app, update `helm/world-cup/values.yaml` with real values
from `terraform output`:

```bash
# Get the ESO role ARN
terraform -chdir=terraform/platform output eso_role_arn
```

```bash
# Get the RDS endpoint (strip the port — just the hostname)
terraform -chdir=terraform/platform output rds_endpoint
```

```bash
# Get the RDS managed secret ARN
terraform -chdir=terraform/platform output db_secret_arn
```

Open `helm/world-cup/values.yaml` and set:
- `esoRoleArn` → value of `eso_role_arn`
- `db.host` → hostname part of `rds_endpoint` (before the colon)
- `secrets.dbSecretArn` → value of `db_secret_arn`

Commit and push this to main so ArgoCD can read it.


## 7. Register your GitHub repo with ArgoCD

```bash
# Log into ArgoCD CLI (port-forward from step 5 must be running)
argocd login localhost:8080 --username admin --password <password> --insecure
```

```bash
# Generate an SSH deploy key — ArgoCD uses this to read the repo
ssh-keygen -t ed25519 -f argocd-deploy-key -N ""
# Add argocd-deploy-key.pub to GitHub repo → Settings → Deploy keys (read-only)
```

```bash
# Register the repo with ArgoCD using the private key
argocd repo add git@github.com:Eniadebisi/Solutions_Architect.git \
  --ssh-private-key-path argocd-deploy-key
```


## 8. Apply the ArgoCD Application

```bash
# Creates the Application object — ArgoCD will start syncing immediately
kubectl apply -f argocd/app.yaml
```

```bash
# Check sync status — should move from OutOfSync → Synced
argocd app get world-cup
```

```bash
# Watch it sync in real time
argocd app wait world-cup --sync --timeout 120
```

```bash
# If sync fails, show the error
argocd app get world-cup --show-operation
```


## 9. Verify secrets synced via ESO

```bash
# ExternalSecret status — Ready=True means secrets are live in the cluster
kubectl get externalsecret -n world-cup
```

```bash
# Detailed status if it's not Ready
kubectl describe externalsecret world-cup-secrets -n world-cup
```

```bash
# Confirm the Kubernetes Secret was created (ESO writes it)
kubectl get secret world-cup-secrets -n world-cup
```


## 10. Verify the application is running

```bash
# Check pods — should show 2 Running pods
kubectl get pods -n world-cup
```

```bash
# If a pod is not Running, describe it — events section shows the cause
kubectl describe pod -l app=world-cup-api -n world-cup
```

```bash
# View live logs from all app pods
kubectl logs -l app=world-cup-api -n world-cup --follow
```

```bash
# Port-forward the app to localhost and test the health endpoint
kubectl port-forward svc/world-cup-api 8000:8080 -n world-cup
# In a second terminal:
curl http://localhost:8000/health
```


## 11. Test a full deploy cycle (GitOps loop)

```bash
# Push a new image to ECR (replace <tag> with a version)
aws ecr get-login-password --region us-east-1 --profile world-cup \
  | docker login --username AWS --password-stdin \
    866934333672.dkr.ecr.us-east-1.amazonaws.com
```

```bash
docker build -t world-cup .
docker tag world-cup:latest \
  866934333672.dkr.ecr.us-east-1.amazonaws.com/world-cup:<tag>
docker push 866934333672.dkr.ecr.us-east-1.amazonaws.com/world-cup:<tag>
```

```bash
# Update the image tag in values.yaml, commit, and push to main
# ArgoCD detects the change within 3 minutes and rolls out the new version
```

```bash
# Watch the rollout
kubectl rollout status deployment/world-cup-api -n world-cup
```

```bash
# Confirm the running pods are using the new image
kubectl get pods -n world-cup -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}'
```


## Common failures and fixes

| Symptom | Check |
|---|---|
| `ImagePullBackOff` | No image in ECR yet — push one first |
| `CreateContainerConfigError` | ESO hasn't synced — check step 9 |
| `CrashLoopBackOff` | App failing to start — check logs in step 10 |
| ArgoCD `ConnectionFailed` | Deploy key not added to GitHub repo |
| ArgoCD `OutOfSync` (never syncs) | ESO CRDs not installed — redo step 4 |
| Nodes `NotReady` | Node group still launching — wait 2-3 min and retry |
