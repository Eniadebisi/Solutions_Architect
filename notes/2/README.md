# Domain 2: Design Resilient Architectures (26%)

## [Amazon Route 53](Route53/README.md) - [AWS Doc](https://docs.aws.amazon.com/route53/)
- [ ] Configure DNS routing policies: Latency, Geolocation, Geoproximity, and Weighted distribution.
- [ ] Design active-passive failover mechanisms driven by Route 53 Health Checks.
- [ ] Resolve split-horizon hybrid DNS architectures using Route 53 Resolver endpoints.

## [Amazon EC2 Auto Scaling & Elastic Load Balancing (ELB)](Auto-Scaling-ELB/README.md) - [AWS Doc](https://docs.aws.amazon.com/autoscaling/ec2/)
- [ ] Deploy multi-AZ infrastructure topologies using Application Load Balancers (ALB) and Network Load Balancers (NLB).
- [ ] Set up Auto Scaling Groups (ASG) with Dynamic Scaling policies (Target Tracking, Step, Simple).
- [ ] Handle stateful instance teardown gracefully using Auto Scaling Lifecycle Hooks.

## [AWS Lambda & AWS Fargate](Lambda/README.md) - [AWS Doc](https://docs.aws.amazon.com/lambda/)
- [ ] Architect stateless microservices layers using event-driven Lambda execution models.
- [ ] Enforce memory allocation boundaries and compute timeout limits.
- [ ] Package and run serverless, containerized workloads via Fargate integrated with [Amazon ECS](https://docs.aws.amazon.com/ecs/) or [Amazon EKS](https://docs.aws.amazon.com/eks/).
    - [ECS](ECS/README.md)
    - [EKS](EKS/README.md)

## [Amazon SQS & Amazon SNS](SQS-SNS/README.md) - [AWS Doc](https://docs.aws.amazon.com/sqs/)
- [ ] Loose-couple distributed sub-systems using Standard vs FIFO message queues.
- [ ] Isolate ingestion or compute payload faults via SQS Dead-Letter Queues (DLQs) and Visibility Timeouts.
- [ ] Broadcast pub/sub messaging topologies utilizing SNS Fan-out architectures and Subscription Filter Policies.

## [AWS Application Integration & Orchestration](Step-Functions/README.md) - [AWS Doc](https://docs.aws.amazon.com/step-functions/)
- [ ] Orchestrate multi-tier application workflows through state machine state tracking via AWS Step Functions.
- [ ] Standardize event-driven microservice networks using [Amazon EventBridge](https://docs.aws.amazon.com/eventbridge/) buses.
- [ ] Manage secure file ingest channels via [AWS Transfer Family](https://docs.aws.amazon.com/transfer/).

## [AWS CloudWatch & AWS X-Ray](CloudWatch/README.md) - [AWS Doc](https://docs.aws.amazon.com/cloudwatch/)
- [ ] Implement comprehensive workload visibility across distributed microservices with X-Ray tracing.
- [ ] Create automation routines to maintain infrastructure integrity based on CloudWatch Metrics and Alarms.
