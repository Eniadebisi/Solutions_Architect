# EKS — Elastic Kubernetes Service

## What it does

EKS is a managed Kubernetes control plane. AWS runs and manages the API server, etcd, controller manager, and scheduler. You are responsible for the worker nodes (EC2 instances) that actually run your pods.

Kubernetes is a container orchestrator. It takes your container image, decides which node to schedule it on, restarts it if it crashes, scales it up or down, and routes traffic to it.

## Key concepts

**Control plane** — the Kubernetes brain. API server handles all kubectl commands and API calls. etcd is the key-value store holding all cluster state. Controller manager runs control loops (e.g. the ReplicaSet controller ensures the right number of pods are running). Scheduler decides which node a new pod goes on. AWS manages all of this in EKS — you pay $0.10/hour for the control plane regardless of how many nodes you have.

**Node group** — a group of EC2 instances that serve as worker nodes. A managed node group means AWS handles provisioning, draining, and updating the EC2 instances. You define the instance type, min/max count, and subnets.

**Pod** — the smallest deployable unit in Kubernetes. Usually one container per pod. Pods are ephemeral — Kubernetes restarts or reschedules them, they do not persist state.

**Deployment** — a controller that ensures a specified number of pod replicas are running. If a pod dies, the Deployment controller creates a new one. This is what you use for the world-cup-api.

**CronJob** — a Kubernetes object that runs a pod on a schedule (cron syntax). Used for the world-cup-cron daily fetch. After the pod completes, it is cleaned up automatically.

**Service** — gives pods a stable network endpoint. Pods have dynamic IPs that change when rescheduled; a Service provides a fixed DNS name and IP that routes to healthy pods.

**Namespace** — a virtual cluster inside the cluster. Used to isolate workloads. You deploy world-cup resources into a `world-cup` namespace; ArgoCD has its own `argocd` namespace.

**OIDC provider** — OpenID Connect identity provider registered with the EKS cluster. Enables IRSA — pods can assume IAM roles without storing credentials.

**IRSA (IAM Roles for Service Accounts)** — when a Kubernetes service account is annotated with an IAM role ARN, pods using that service account receive a token. AWS STS validates the token against the OIDC provider and returns temporary AWS credentials. The pod never sees an access key.

**kubeconfig** — a local file (`~/.kube/config`) that tells `kubectl` which cluster to talk to and how to authenticate. `aws eks update-kubeconfig` generates this for you.

## EKS setup in this project

- Cluster name: `world-cup`
- Kubernetes version: 1.31
- Node group: 2× `t3.small` spot, private subnets only
- IRSA enabled
- Add-ons: `vpc-cni` (networking), `coredns` (DNS), `kube-proxy` (iptables)

## Terraform resources involved

- `aws_eks_cluster`
- `aws_eks_node_group`
- `aws_iam_role` (cluster role, node group role)
- `aws_iam_role_policy_attachment` (multiple AWS-managed policies)
- `aws_iam_openid_connect_provider` (for IRSA)
- `aws_launch_template` (optional, for custom node config)
- `aws_eks_addon` (vpc-cni, coredns, kube-proxy)

Community module: `terraform-aws-modules/eks/aws`

## Terraform setup

Module in `terraform/platform/eks/`. Calls the reusable module at `terraform/modules/eks/`. Uses `terraform-aws-modules/eks/aws`:

```hcl
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket  = "world-cup-tfstate"
    key     = "platform/vpc/terraform.tfstate"
    region  = "us-east-1"
    profile = "world-cup"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "world-cup"
  cluster_version = "1.31"

  vpc_id     = data.terraform_remote_state.vpc.outputs.eks_vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.eks_private_subnet_ids

  enable_irsa = true

  eks_managed_node_groups = {
    world-cup = {
      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
      min_size       = 2
      max_size       = 4
      desired_size   = 2
    }
  }
}
```

After apply, update your kubeconfig and verify nodes are `Ready`:

```bash
aws eks update-kubeconfig --name world-cup --region us-east-1 --profile world-cup
kubectl get nodes
aws eks describe-cluster --name world-cup \
  --query "cluster.identity.oidc.issuer" --profile world-cup
```

The OIDC issuer URL confirms IRSA is available.

## CLI commands

```bash
# Update local kubeconfig to point at the EKS cluster
aws eks update-kubeconfig --name world-cup --region us-east-1 --profile world-cup

# View nodes and their status
kubectl get nodes -o wide

# Describe a node (shows resource capacity, taints, conditions)
kubectl describe node <node-name>

# View all pods across all namespaces
kubectl get pods -A

# View pods in the world-cup namespace
kubectl get pods -n world-cup

# View pod logs (live tail)
kubectl logs -f <pod-name> -n world-cup

# View logs for all pods with a label
kubectl logs -l app=world-cup-api -n world-cup

# Describe a pod (events section shows scheduling failures)
kubectl describe pod <pod-name> -n world-cup

# Execute a command inside a running pod
kubectl exec -it <pod-name> -n world-cup -- /bin/sh

# Port-forward a service to localhost
kubectl port-forward svc/world-cup-api 8000:8000 -n world-cup

# View resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods -n world-cup

# List deployments
kubectl get deployments -n world-cup

# Restart a deployment (rolling restart of all pods)
kubectl rollout restart deployment/world-cup-api -n world-cup

# View rollout status
kubectl rollout status deployment/world-cup-api -n world-cup

# View events (useful for diagnosing ImagePullBackOff, OOMKilled etc.)
kubectl get events -n world-cup --sort-by='.lastTimestamp'

# Show cluster info
kubectl cluster-info

# List EKS clusters in your account
aws eks list-clusters --profile world-cup

# Describe the cluster (shows OIDC issuer, Kubernetes version, status)
aws eks describe-cluster --name world-cup --profile world-cup

# List node groups
aws eks list-nodegroups --cluster-name world-cup --profile world-cup

# Scale node group up or down
aws eks update-nodegroup-config \
  --cluster-name world-cup \
  --nodegroup-name world-cup-nodes \
  --scaling-config minSize=0,maxSize=4,desiredSize=0 \
  --profile world-cup
```

## Common pod failure states

| Status | Cause | Fix |
|---|---|---|
| `ImagePullBackOff` | Cannot pull image from ECR | Check node IAM role has `ecr:GetAuthorizationToken` and `ecr:BatchGetImage` |
| `CrashLoopBackOff` | Container starts then exits | Check logs: `kubectl logs <pod>` — usually a missing env var or DB connection failure |
| `Pending` | Pod cannot be scheduled | Check events — usually insufficient node resources or no nodes match node selector |
| `OOMKilled` | Container exceeded memory limit | Increase memory limit in Helm values or reduce app memory usage |
| `CreateContainerConfigError` | Referenced secret does not exist | ESO has not synced yet — check ExternalSecret status |

## Official docs

- [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
- [Managed node groups](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)
- [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [EKS add-ons](https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html)
