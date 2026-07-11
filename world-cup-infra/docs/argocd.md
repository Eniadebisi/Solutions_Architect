# ArgoCD

## What it does

ArgoCD is a GitOps continuous delivery tool for Kubernetes. It watches a Git repository and continuously ensures the cluster state matches what is declared in that repo. When the repo changes (e.g. a new image tag in `values.yaml`), ArgoCD detects the diff and reconciles the cluster to match.

The core principle: Git is the single source of truth. You never run `kubectl apply` manually in production. You commit to Git, and ArgoCD applies it.

## Key concepts

**GitOps** — a deployment model where the desired state of infrastructure or applications is declared in Git. The running system is continuously reconciled to match. Benefits: full audit log (Git history), easy rollback (revert a commit), no manual cluster access needed for deploys.

**Application** — an ArgoCD CRD that defines what to deploy. It specifies the source (Git repo + path + revision) and the destination (Kubernetes cluster + namespace). ArgoCD continuously watches the source and syncs the destination to match.

**Sync** — the act of applying the diff between the desired state (Git) and the actual state (cluster). Sync can be manual (you click a button or run `argocd app sync`) or automatic (ArgoCD applies changes as soon as it detects them).

**Self-heal** — if someone manually runs `kubectl apply` or edits a resource directly, ArgoCD detects the drift and reverts it back to what Git says. Enabled with `syncPolicy.automated.selfHeal: true`.

**App of apps** — a pattern where one ArgoCD Application points at a directory of other Application manifests. Used for managing many apps from a single root. Not required for this project (one app only) but worth knowing.

**Helm integration** — ArgoCD can render a Helm chart and apply the output. You point it at your `helm/world-cup/` directory and provide `values.yaml`. ArgoCD renders the chart and applies the manifests directly — no separate `helm install` needed.

**Health checks** — ArgoCD knows how to assess the health of standard Kubernetes resources (Deployments, Services, etc.) and shows green/yellow/red status per resource. Custom health checks can be written in Lua.

**RBAC** — ArgoCD has its own RBAC separate from Kubernetes RBAC. You can give a team read-only access to the ArgoCD UI without giving them `kubectl` access.

## ArgoCD Application manifest

This lives at `argocd/app.yaml` in the infra repo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: world-cup
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Eniadebisi/Solutions_Architect.git
    targetRevision: main
    path: world-cup-infra/helm/world-cup
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: world-cup
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Key fields:
- `repoURL` — your infra repo. ArgoCD needs read access (GitHub deploy key or GitHub App)
- `path` — the subdirectory containing the Helm chart, relative to the repo root
- `targetRevision: main` — always deploy from the `main` branch
- `automated.prune: true` — if you remove a resource from Git, ArgoCD deletes it from the cluster
- `automated.selfHeal: true` — revert manual cluster changes
- `CreateNamespace=true` — ArgoCD creates the `world-cup` namespace if it does not exist

## Installing ArgoCD

```bash
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=ClusterIP \
  --set configs.params."server\.insecure"=true
```

`server.insecure=true` disables TLS termination at ArgoCD (you are using port-forward locally, not a public ingress). Remove this if you add an Ingress with TLS later.

## CLI commands

```bash
# Install ArgoCD CLI (macOS)
brew install argocd

# Install ArgoCD CLI (Linux)
curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Port-forward the ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get the initial admin password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d

# Login via CLI
argocd login localhost:8080 --username admin --password <password> --insecure

# List all applications
argocd app list

# Get application status
argocd app get world-cup

# Manually sync an application
argocd app sync world-cup

# Wait for sync to complete
argocd app wait world-cup --sync

# View sync history (which Git commits were deployed and when)
argocd app history world-cup

# Rollback to a previous sync
argocd app rollback world-cup <history-id>

# Refresh (re-read Git without syncing)
argocd app get world-cup --refresh

# Show the diff between Git and cluster
argocd app diff world-cup

# Delete an application (does not delete cluster resources by default)
argocd app delete world-cup

# Delete an application and all its cluster resources
argocd app delete world-cup --cascade

# Add a repo via SSH deploy key (preferred — see GitHub repo access section below)
argocd repo add git@github.com:Eniadebisi/Solutions_Architect.git \
  --ssh-private-key-path argocd-deploy-key

# Apply the Application manifest
kubectl apply -f argocd/app.yaml

# View ArgoCD logs
kubectl logs -l app.kubernetes.io/name=argocd-application-controller \
  -n argocd --tail=50
```

## GitHub repo access

ArgoCD needs to read your `world-cup-infra` repo. The cleanest approach for GitHub is a **deploy key**:

1. Generate a key pair: `ssh-keygen -t ed25519 -f argocd-deploy-key -N ""`
2. Add the public key to the GitHub repo under Settings → Deploy keys (read-only)
3. Add the private key to ArgoCD: `argocd repo add git@github.com:Eniadebisi/Solutions_Architect.git --ssh-private-key-path argocd-deploy-key`

## The deploy loop

When the app pipeline merges a PR updating `values.yaml`:

1. GitHub webhook (or ArgoCD polling every 3 min) detects the change
2. ArgoCD computes the diff — the `image.tag` in the Deployment changed
3. ArgoCD patches the Deployment with the new image tag
4. Kubernetes performs a rolling update — new pods start, old pods terminate after readiness check passes
5. ArgoCD reports `Synced` and `Healthy`

The entire flow from merge to running pod takes 2-5 minutes depending on image pull time.

## Common issues

**App shows `OutOfSync` but sync fails** — usually a Helm rendering error. Check: `argocd app get world-cup` for the error message. Often a missing value in `values.yaml` or a broken template.

**App shows `Degraded`** — a resource is unhealthy. Drill into the specific resource: `argocd app get world-cup --show-operation`. Then check: `kubectl describe pod <pod> -n world-cup`.

**Repo `ConnectionFailed`** — ArgoCD cannot read the Git repo. Check the deploy key is added and the repo URL matches exactly (HTTPS vs SSH).

**Infinite sync loop** — a resource's live state never matches the desired state. Often caused by a field that Kubernetes mutates after apply (e.g. `status` fields or admission webhook mutations). Add the field to ArgoCD's ignore differences config.

## Official docs

- [ArgoCD overview](https://argo-cd.readthedocs.io/en/stable/)
- [Application spec reference](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)
- [GitOps overview](https://argo-cd.readthedocs.io/en/stable/core_concepts/)
- [Helm integration](https://argo-cd.readthedocs.io/en/stable/user-guide/helm/)
- [RBAC config](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
