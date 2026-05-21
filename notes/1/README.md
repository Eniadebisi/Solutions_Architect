# Domain 1: Design Secure Architectures (30%)

## [IAM (Identity and Access Management]() - [AWS Doc](https://docs.aws.amazon.com/iam/)
- [ ] Implement multi-factor authentication (MFA) for root and administrative users.
- [ ] Build a flexible authorization model using IAM groups, customer-managed policies, and inline boundaries.
- [ ] Establish role-based access control (RBAC) across cross-account structures using [STS](https://docs.aws.amazon.com/STS/) assume-role mechanisms.
- [ ] Configure resource-based policies for S3 and KMS to allow cross-account principal actions.
- [ ] Integrate external directory services (SAML 2.0, OIDC) with IAM role trust relationships.

## [IAM Identity Center / Organizations]() - [AWS Doc](https://docs.aws.amazon.com/organizations/)
- [ ] Design multi-account architecture landing zones with centralized single sign-on via Identity Center.
- [ ] Enforce guardrails across Organizational Units (OUs) utilizing Service Control Policies (SCPs).
- [ ] Standardize environments via [Control Tower](https://docs.aws.amazon.com/controltower/) account factory mechanics.

## [Amazon VPC Security & Core Networking]() - [AWS Doc](https://docs.aws.amazon.com/vpc/)
- [ ] Implement network segmentation with strict Public/Private subnet route configurations.
- [ ] Configure stateful Security Groups and stateless Network Access Control Lists (NACLs) to manage traffic ports/protocols.
- [ ] Establish secure ingestion points via [Secrets Manager](https://docs.aws.amazon.com/secretsmanager/) VPC Interface Endpoints.
- [ ] Capture fine-grained ingestion access telemetry via VPC Flow Logs.

## [Edge Security & Perimeter Defense]() - [AWS Doc](https://docs.aws.amazon.com/waf/)
- [ ] Defend application layer workloads from SQL injection and cross-site scripting using WAF Web ACLs.
- [ ] Deploy [Shield Advanced](https://docs.aws.amazon.com/shield/) to mitigate volumetric DDoS threat vectors.
- [ ] Secure hybrid connections with [Site-to-Site VPN](https://docs.aws.amazon.com/vpn/) and [Direct Connect](https://docs.aws.amazon.com/directconnect/).
- [ ] Implement managed detection utilizing [Amazon GuardDuty](https://docs.aws.amazon.com/guardduty/) and data classification via [Amazon Macie](https://docs.aws.amazon.com/macie/).

## [AWS KMS & Data Encryption]() - [AWS Doc](https://docs.aws.amazon.com/kms/)
- [ ] Implement encryption-at-rest across data planes utilizing Customer Managed Keys (CMKs) vs AWS Managed Keys.
- [ ] Define explicit resource access controls via KMS Key Policies.
- [ ] Automate envelope encryption workflows alongside scheduled key rotation routines.
- [ ] Provision encryption-in-transit certificates using [AWS Certificate Manager (ACM)](https://docs.aws.amazon.com/acm/) tied to TLS endpoints.
