# VPC — Virtual Private Cloud

## What it does

A VPC is a logically isolated network inside AWS. Everything you create (EC2 instances, EKS nodes, RDS) lives inside a VPC. You control the IP address range, subnet layout, routing, and what can communicate with what.

Without a VPC there is no networking. It is the foundation every other service builds on.

## Key concepts

**CIDR block** — the IP range for the entire VPC. `10.0.0.0/16` gives you 65,536 addresses. All subnets must be subsets of this range.

**Subnet** — a slice of the VPC CIDR in a single Availability Zone. A subnet is either public (has a route to the internet via an Internet Gateway) or private (no direct internet route). Resources in private subnets cannot be reached from the internet and cannot reach it unless you add a NAT Gateway or VPC endpoint.

**Internet Gateway (IGW)** — attached to the VPC, allows traffic between public subnets and the internet. One per VPC.

**Route table** — a set of rules that determine where traffic goes. Each subnet is associated with exactly one route table. A public subnet's route table has a rule: `0.0.0.0/0 → igw-xxxxxxxx`. A private subnet's route table has no such rule.

**Security group** — a stateful firewall attached to a resource (EC2 instance, RDS instance, EKS node). Controls inbound and outbound traffic by port, protocol, and source/destination. Think of it as a per-resource firewall, not a subnet firewall.

**VPC Flow Logs** — captures metadata (not content) about traffic flowing through the VPC. Useful for debugging connectivity issues. Writes to CloudWatch Logs or S3.

**NACL (Network ACL)** — subnet-level stateless firewall. Less commonly used than security groups for application-level control. You will use the default (allow all) for learning.

## Architecture in this project

One VPC, three subnet tiers in two Availability Zones:

| VPC | CIDR | Purpose |
|---|---|---|
| world-cup-vpc | 10.0.0.0/16 | All resources — LB, EKS nodes, RDS |

Subnets:

| Subnet | CIDR | AZ | Type | Contains |
|---|---|---|---|---|
| public-1 | 10.0.1.0/24 | us-east-1a | Public | Load balancer |
| public-2 | 10.0.2.0/24 | us-east-1b | Public | Load balancer |
| eks-1 | 10.0.3.0/24 | us-east-1a | Private | EKS nodes |
| eks-2 | 10.0.4.0/24 | us-east-1b | Private | EKS nodes |
| rds-1 | 10.0.5.0/24 | us-east-1a | Private | RDS |
| rds-2 | 10.0.6.0/24 | us-east-1b | Private | RDS |

Security groups (traffic flows only along the arrows):

```
Internet → lb-sg (80/443) → eks-nodes-sg (container port) → rds-sg (5432)
```

## Terraform resources involved

- `aws_vpc`
- `aws_subnet`
- `aws_internet_gateway`
- `aws_route_table`, `aws_route_table_association`
- `aws_db_subnet_group`
- `aws_security_group` (lb, eks-nodes, rds, vpc-endpoints)
- `aws_vpc_endpoint` (s3 gateway + ecr.api, ecr.dkr, secretsmanager, sts, logs interfaces)
- `aws_flow_log`, `aws_cloudwatch_log_group`, `aws_iam_role`

Module lives at `terraform/modules/networking/`. Called from `terraform/platform/main.tf`.

## Terraform setup

```hcl
module "networking" {
  source = "../modules/networking"

  project_name        = "world-cup"
  cluster_name        = "world-cup"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  eks_subnet_cidrs    = ["10.0.3.0/24", "10.0.4.0/24"]
  rds_subnet_cidrs    = ["10.0.5.0/24", "10.0.6.0/24"]
  container_port      = 8080
}
```

Key outputs consumed by other modules:

| Output | Used by |
|---|---|
| `vpc_id` | EKS, RDS modules |
| `eks_subnet_ids` | EKS node group |
| `public_subnet_ids` | Load balancer |
| `rds_subnet_ids`, `rds_subnet_group_name` | RDS module |
| `eks_nodes_sg_id` | EKS node group |
| `rds_sg_id` | RDS module |
| `lb_sg_id` | Load balancer / Ingress annotations |

## CLI commands

```bash
# List all VPCs in your account
aws ec2 describe-vpcs --profile world-cup \
  --query "Vpcs[].{Id:VpcId,CIDR:CidrBlock,Name:Tags[?Key=='Name']|[0].Value}"

# List subnets in a specific VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>" \
  --profile world-cup \
  --query "Subnets[].{Name:Tags[?Key=='Name']|[0].Value,CIDR:CidrBlock,AZ:AvailabilityZone,Public:MapPublicIpOnLaunch}"

# Show route tables for a VPC
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>" \
  --profile world-cup \
  --query "RouteTables[].{Id:RouteTableId,Routes:Routes[].{Dest:DestinationCidrBlock,Target:GatewayId}}"

# Describe security groups in a VPC
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<vpc-id>" \
  --profile world-cup \
  --query "SecurityGroups[].{Name:GroupName,Id:GroupId}"

# View flow logs for a VPC
aws ec2 describe-flow-logs --filter "Name=resource-id,Values=<vpc-id>" \
  --profile world-cup

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=<vpc-id>" \
  --profile world-cup \
  --query "VpcEndpoints[].{Service:ServiceName,Type:VpcEndpointType,State:State}"
```

## Debugging connectivity

If a pod cannot reach RDS, check these in order:

1. Pod is running in a private subnet node (`kubectl get node -o wide`)
2. Security group on RDS allows inbound 5432 from the EKS node security group
3. Security group on EKS nodes allows outbound (default AWS egress allows all)
4. No NACL blocking (default NACL allows all)

```bash
# Test from inside the cluster using a debug pod
kubectl run nettest --image=nicolaka/netshoot --rm -it --restart=Never \
  -- nc -zv <rds-endpoint> 5432
```

Output `Connection to <host> 5432 port [tcp/postgresql] succeeded!` means the network path is clear.

If a node cannot pull images from ECR, the VPC endpoint for `ecr.dkr` or `ecr.api` may not be in place:

```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=<vpc-id>" "Name=service-name,Values=*ecr*" \
  --profile world-cup \
  --query "VpcEndpoints[].{Service:ServiceName,State:State}"
```

## Official docs

- [VPC overview](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html)
- [Route tables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html)
- [Security groups](https://docs.aws.amazon.com/vpc/latest/userguide/security-groups.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
- [VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
