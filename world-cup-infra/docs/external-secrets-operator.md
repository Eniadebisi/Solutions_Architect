# External Secrets Operator (ESO)

## What it does

ESO is a Kubernetes controller that reads secrets from external secret stores (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, etc.) and creates native Kubernetes `Secret` objects from them. It keeps the K8s secrets in sync with the external store on a configurable schedule.

Without ESO, you would have to manually create K8s secrets, remember to update them when the upstream value changes, and make sure they never appear in your Git history. ESO automates all of that.

## Key concepts

**SecretStore / ClusterSecretStore** — tells ESO where to find secrets and how to authenticate. A `SecretStore` is namespaced (only usable in one namespace). A `ClusterSecretStore` is cluster-wide. In this project you use a `ClusterSecretStore` backed by AWS Secrets Manager, authenticating via IRSA.

**ExternalSecret** — a CRD (Custom Resource Definition) you create in your namespace. It references a `SecretStore` and specifies which keys to pull from the external store and what to name them in the resulting K8s `Secret`. This lives in your Helm chart at `templates/externalsecret.yaml`.

**refreshInterval** — how often ESO re-reads the external secret and updates the K8s secret. Default is 1 hour. Set to `1m` during development so changes propagate quickly.

**K8s Secret** — the native Kubernetes object that ESO creates. Your pod references this in its `env` block via `secretKeyRef`. The pod sees plain environment variables — it has no knowledge of ESO or Secrets Manager.

## How the data flows

```
AWS Secrets Manager
    world-cup/db  →  {"host":"...", "port":"5432", "password":"..."}
         ↓
    ESO reads via IRSA (no credentials stored anywhere)
         ↓
    Kubernetes Secret: world-cup-db-secret
         ↓
    Pod env vars: DB_HOST, DB_PORT, DB_PASSWORD
         ↓
    config.py (pydantic-settings reads os.environ)
```

## Manifests in this project

**ClusterSecretStore** (applied once, lives outside the Helm chart):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets
```

**ExternalSecret — DB** (in `helm/world-cup/templates/externalsecret-db.yaml`):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: world-cup-db-secret
  namespace: world-cup
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: world-cup-db-secret
    creationPolicy: Owner
  data:
    - secretKey: host
      remoteRef:
        key: world-cup/db
        property: host
    - secretKey: port
      remoteRef:
        key: world-cup/db
        property: port
    - secretKey: username
      remoteRef:
        key: world-cup/db
        property: username
    - secretKey: password
      remoteRef:
        key: world-cup/db
        property: password
```

**ExternalSecret — Football API** (in `helm/world-cup/templates/externalsecret-football-api.yaml`):

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: world-cup-football-api-secret
  namespace: world-cup
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: world-cup-football-api-secret
    creationPolicy: Owner
  data:
    - secretKey: FOOTBALL_API_KEY
      remoteRef:
        key: world-cup/football-api
        property: FOOTBALL_API_KEY
    - secretKey: FOOTBALL_API_URL
      remoteRef:
        key: world-cup/football-api
        property: FOOTBALL_API_URL
```

Both secrets must exist before pods start. The app deployment should reference both via `envFrom` or individual `secretKeyRef` entries.

## CLI commands

```bash
# Check ESO pods are running
kubectl get pods -n external-secrets

# Check all ExternalSecrets and their sync status
kubectl get externalsecret -A

# Check a specific ExternalSecret (Ready: True means synced)
kubectl get externalsecret world-cup-db-secret -n world-cup -o yaml

# Force a re-sync immediately
kubectl annotate externalsecret world-cup-db-secret \
  force-sync=$(date +%s) --overwrite -n world-cup

# View the resulting K8s secret (values are base64 encoded)
kubectl get secret world-cup-db-secret -n world-cup -o yaml

# Decode a specific key from the secret
kubectl get secret world-cup-db-secret -n world-cup \
  -o jsonpath="{.data.host}" | base64 -d

# Check ClusterSecretStore status
kubectl get clustersecretstore

# Describe a ClusterSecretStore (shows conditions and any errors)
kubectl describe clustersecretstore aws-secrets-manager

# View ESO controller logs
kubectl logs -l app.kubernetes.io/name=external-secrets \
  -n external-secrets --tail=50

# View ESO webhook logs (useful for CRD admission errors)
kubectl logs -l app.kubernetes.io/name=external-secrets-webhook \
  -n external-secrets --tail=20
```

## Installing ESO

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::<account>:role/world-cup-eso-role
```

The `serviceAccount.annotations` line wires the IRSA role to the ESO service account at install time.

## Common issues

**`SecretStore` shows `Ready: False` with `InvalidProviderConfig`** — the IRSA role ARN is wrong or the trust policy does not match the ESO service account name/namespace. Verify:

```bash
kubectl describe clustersecretstore aws-secrets-manager
```

Look at the `Conditions` section for the error message.

**`ExternalSecret` shows `SecretSyncedError`** — ESO can reach Secrets Manager but the secret name or property key does not exist. Secret names and property keys are case-sensitive. Verify the secret name in Secrets Manager matches exactly what is in the ExternalSecret manifest.

**Pod has `CreateContainerConfigError`** — the K8s secret referenced in the pod spec does not exist yet. Check the ExternalSecret status. If ESO is still syncing (takes a few seconds after apply), the pod will recover automatically once the secret exists.

**Cert-manager conflict** — ESO requires its own webhook TLS certs. If cert-manager is already installed in the cluster, pass `--set certController.enabled=false` to the ESO Helm install to avoid conflicts and let cert-manager handle it.

## Official docs

- [ESO overview](https://external-secrets.io/latest/)
- [AWS Secrets Manager provider](https://external-secrets.io/latest/provider/aws-secrets-manager/)
- [ExternalSecret API reference](https://external-secrets.io/latest/api/externalsecret/)
- [ClusterSecretStore API reference](https://external-secrets.io/latest/api/clustersecretstore/)
- [IRSA setup with EKS](https://external-secrets.io/latest/provider/aws-secrets-manager/#eks-service-account-credentials-irsa)
