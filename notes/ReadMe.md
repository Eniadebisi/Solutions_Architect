# [AWS Certified Solutions Architect - Associate (SAA-C03)](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03/solutions-architect-associate-03.html)

## Domain 1: Design Secure Architectures (30%)

### [AWS IAM (Identity and Access Management)](https://docs.aws.amazon.com/iam/)
- [ ] Implement multi-factor authentication (MFA) for root and administrative users.
- [ ] Build a flexible authorization model using IAM groups, customer-managed policies, and inline boundaries.
- [ ] Establish role-based access control (RBAC) across cross-account structures using [AWS STS](https://docs.aws.amazon.com/STS/) assume-role mechanisms.
- [ ] Configure resource-based policies for Amazon S3 and AWS KMS to allow cross-account principal actions.
- [ ] Integrate external directory services (SAML 2.0, OIDC) with IAM role trust relationships.

### [AWS IAM Identity Center / AWS Organizations](https://docs.aws.amazon.com/organizations/)
- [ ] Design multi-account architecture landing zones with centralized single sign-on via Identity Center.
- [ ] Enforce guardrails across Organizational Units (OUs) utilizing Service Control Policies (SCPs).
- [ ] Standardize environments via [AWS Control Tower](https://docs.aws.amazon.com/controltower/) account factory mechanics.

### [Amazon VPC Security & Core Networking](https://docs.aws.amazon.com/vpc/)
- [ ] Implement network segmentation with strict Public/Private subnet route configurations.
- [ ] Configure stateful Security Groups and stateless Network Access Control Lists (NACLs) to manage traffic ports/protocols.
- [ ] Establish secure ingestion points via [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/) VPC Interface Endpoints.
- [ ] Capture fine-grained ingestion access telemetry via VPC Flow Logs.

### [AWS Edge Security & Perimeter Defense](https://docs.aws.amazon.com/waf/)
- [ ] Defend application layer workloads from SQL injection and cross-site scripting using AWS WAF Web ACLs.
- [ ] Deploy [AWS Shield Advanced](https://docs.aws.amazon.com/shield/) to mitigate volumetric DDoS threat vectors.
- [ ] Secure hybrid connections with [AWS Site-to-Site VPN](https://docs.aws.amazon.com/vpn/) and [AWS Direct Connect](https://docs.aws.amazon.com/directconnect/).
- [ ] Implement managed detection utilizing [Amazon GuardDuty](https://docs.aws.amazon.com/guardduty/) and data classification via [Amazon Macie](https://docs.aws.amazon.com/macie/).

### [AWS KMS & Data Encryption](https://docs.aws.amazon.com/kms/)
- [ ] Implement encryption-at-rest across data planes utilizing Customer Managed Keys (CMKs) vs AWS Managed Keys.
- [ ] Define explicit resource access controls via KMS Key Policies.
- [ ] Automate envelope encryption workflows alongside scheduled key rotation routines.
- [ ] Provision encryption-in-transit certificates using [AWS Certificate Manager (ACM)](https://docs.aws.amazon.com/acm/) tied to TLS endpoints.

---

## Domain 2: Design Resilient Architectures (26%)

### [Amazon Route 53](https://docs.aws.amazon.com/route53/)
- [ ] Configure DNS routing policies: Latency, Geolocation, Geoproximity, and Weighted distribution.
- [ ] Design active-passive failover mechanisms driven by Route 53 Health Checks.
- [ ] Resolve split-horizon hybrid DNS architectures using Route 53 Resolver endpoints.

### [Amazon EC2 Auto Scaling & Elastic Load Balancing (ELB)](https://docs.aws.amazon.com/autoscaling/ec2/)
- [ ] Deploy multi-AZ infrastructure topologies using Application Load Balancers (ALB) and Network Load Balancers (NLB).
- [ ] Set up Auto Scaling Groups (ASG) with Dynamic Scaling policies (Target Tracking, Step, Simple).
- [ ] Handle stateful instance teardown gracefully using Auto Scaling Lifecycle Hooks.

### [AWS Lambda & AWS Fargate](https://docs.aws.amazon.com/lambda/)
- [ ] Architect stateless microservices layers using event-driven Lambda execution models.
- [ ] Enforce memory allocation boundaries and compute timeout limits.
- [ ] Package and run serverless, containerized workloads via Fargate integrated with [Amazon ECS](https://docs.aws.amazon.com/ecs/) or [Amazon EKS](https://docs.aws.amazon.com/eks/).

### [Amazon SQS & Amazon SNS](https://docs.aws.amazon.com/sqs/)
- [ ] Loose-couple distributed sub-systems using Standard vs FIFO message queues.
- [ ] Isolate ingestion or compute payload faults via SQS Dead-Letter Queues (DLQs) and Visibility Timeouts.
- [ ] Broadcast pub/sub messaging topologies utilizing SNS Fan-out architectures and Subscription Filter Policies.

### [AWS Application Integration & Orchestration](https://docs.aws.amazon.com/step-functions/)
- [ ] Orchestrate multi-tier application workflows through state machine state tracking via AWS Step Functions.
- [ ] Standardize event-driven microservice networks using [Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/) buses.
- [ ] Manage secure file ingest channels via [AWS Transfer Family](https://docs.aws.amazon.com/transfer/).

### [AWS CloudWatch & AWS X-Ray](https://docs.aws.amazon.com/cloudwatch/)
- [ ] Implement comprehensive workload visibility across distributed microservices with X-Ray tracing.
- [ ] Create automation routines to maintain infrastructure integrity based on CloudWatch Metrics and Alarms.

---

## Domain 3: Design High-Performing Architectures (24%)

### [Amazon EBS & Amazon EFS](https://docs.aws.amazon.com/ebs/)
- [ ] Select block volume classes (`gp3`, `io2 Block Express`) matching targeted IOPS/throughput limits.
- [ ] Implement EBS Multi-Attach patterns to support clustered compute operations.
- [ ] Deploy POSIX-compliant file systems using EFS with appropriate Provisioned/Elastic throughput and General Purpose/Max I/O performance profiles.

### [Amazon S3 (Simple Storage Service)](https://docs.aws.amazon.com/s3/)
- [ ] Optimize high-throughput key-prefix data request rates on S3 buckets.
- [ ] Accelerate file uploads by configuring Multipart Upload mechanics.
- [ ] Streamline low-latency content distribution by proxying S3 origins behind [Amazon CloudFront](https://docs.aws.amazon.com/cloudfront/).

### [Amazon RDS & Amazon Aurora](https://docs.aws.amazon.com/rds/)
- [ ] Mitigate read-intensive workload constraints by scaling out asynchronous Read Replicas.
- [ ] Implement [Amazon RDS Proxy](https://docs.aws.amazon.com/rds/proxy/) pools to optimize application connection scaling limits.
- [ ] Design ultra-low-latency distributed configurations using Aurora Global Databases.

### [Amazon DynamoDB & Amazon ElastiCache](https://docs.aws.amazon.com/amazondynamodb/)
- [ ] Structuralize schema data distribution using optimal Partition Keys (PK) and Sort Keys (SK).
- [ ] Manage throughput constraints using Provisioned (RCU/WCU) vs On-Demand capacity modes.
- [ ] Achieve sub-millisecond data read returns by fronting tables with DynamoDB Accelerator (DAX).
- [ ] Integrate caching strategies via ElastiCache (Redis OSS vs Memcached) to minimize primary database stress.

### [Amazon CloudFront & AWS Global Accelerator](https://docs.aws.amazon.com/cloudfront/)
- [ ] Cache dynamic and static web content at global edge locations using optimized Cache Behaviors and TTLs.
- [ ] Optimize network ingress bottlenecks over the AWS global network using Anycast IPs on Global Accelerator.

### [Amazon Kinesis](https://docs.aws.amazon.com/kinesis/)
- [ ] Architect high-volume data streaming pipelines using Kinesis Data Streams.
- [ ] Calculate ingestion partition limits through active shard tuning.
- [ ] Stream real-time analytical ingest to storage sinks using Kinesis Data Firehose.

### [AWS Analytical Processing & Big Data](https://docs.aws.amazon.com/athena/)
- [ ] Perform serverless, ad-hoc queries against unstructured S3 data pools using Amazon Athena.
- [ ] Provision big-data cluster frameworks utilizing [Amazon EMR](https://docs.aws.amazon.com/emr/).
- [ ] Build automated ETL data transform operations across schemas using [AWS Glue](https://docs.aws.amazon.com/glue/).
- [ ] Deploy petabyte-scale data warehouse solutions with [Amazon Redshift](https://docs.aws.amazon.com/redshift/).

---

## Domain 4: Design Cost-Optimized Architectures (20%)

### [Amazon S3 Lifecycle Management](https://docs.aws.amazon.com/s3/)
- [ ] Implement object tiering configurations (Standard-IA, One Zone-IA, Glacier Flexible, Glacier Deep Archive).
- [ ] Automate object migrations and expirations based on retention patterns using S3 Lifecycle Rules.
- [ ] Assess cross-entity upload billing distributions via S3 Requester Pays settings.

### [AWS Storage Migration & Hybrid Storage](https://docs.aws.amazon.com/storagegateway/)
- [ ] Bridge local environments with cloud storage targets using AWS Storage Gateway (File, Volume, Tape).
- [ ] Migrate bulk data repositories over network paths using [AWS DataSync](https://docs.aws.amazon.com/datasync/).
- [ ] Assess workloads against managed network file stores using [Amazon FSx](https://docs.aws.amazon.com/fsx/) configurations.

### [AWS Compute Purchasing & Optimization](https://docs.aws.amazon.com/ec2/)
- [ ] Align elastic runtime compute patterns to cost-optimized models: Spot Instances, Reserved Instances (RIs), and Savings Plans.
- [ ] Implement EC2 Hibernation behaviors to conserve compute state costs during idle hours.
- [ ] Analyze resource sizing recommendations via [AWS Compute Optimizer](https://docs.aws.amazon.com/compute-optimizer/).

### [AWS Network Cost Management](https://docs.aws.amazon.com/vpc/)
- [ ] Architect cost-efficient internet egress routes (Shared NAT Gateways vs NAT Gateways per AZ vs NAT Instances).
- [ ] Mitigate data transfer fees by routing traffic through VPC Endpoints instead of crossing public routing layers.
- [ ] Evaluate multi-account backbone interconnections via [AWS Transit Gateway](https://docs.aws.amazon.com/transit-gateway/) vs VPC Peering.

### [AWS Cost Governance Tools](https://docs.aws.amazon.com/cost-management/)
- [ ] Organize enterprise infrastructure expenditures using Cost Allocation Tags.
- [ ] Set up budget alerts and threshold notifications via AWS Budgets.
- [ ] Perform historical analysis on cross-account expenditures using AWS Cost Explorer and Cost and Usage Reports (CUR).wwdwd




