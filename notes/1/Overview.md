# Domain 1: Design Secure Architectures (30%)

## [AWS IAM (Identity and Access Management)](https://docs.aws.amazon.com/iam/)
- [ ] Implement multi-factor authentication (MFA) for root and administrative users.
- [ ] Build a flexible authorization model using IAM groups, customer-managed policies, and inline boundaries.
- [ ] Establish role-based access control (RBAC) across cross-account structures using [AWS STS](https://docs.aws.amazon.com/STS/) assume-role mechanisms.
- [ ] Configure resource-based policies for Amazon S3 and AWS KMS to allow cross-account principal actions.
- [ ] Integrate external directory services (SAML 2.0, OIDC) with IAM role trust relationships.

## [AWS IAM Identity Center / AWS Organizations](https://docs.aws.amazon.com/organizations/)
- [ ] Design multi-account architecture landing zones with centralized single sign-on via Identity Center.
- [ ] Enforce guardrails across Organizational Units (OUs) utilizing Service Control Policies (SCPs).
- [ ] Standardize environments via [AWS Control Tower](https://docs.aws.amazon.com/controltower/) account factory mechanics.

## [Amazon VPC Security & Core Networking](https://docs.aws.amazon.com/vpc/)
- [ ] Implement network segmentation with strict Public/Private subnet route configurations.
- [ ] Configure stateful Security Groups and stateless Network Access Control Lists (NACLs) to manage traffic ports/protocols.
- [ ] Establish secure ingestion points via [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/) VPC Interface Endpoints.
- [ ] Capture fine-grained ingestion access telemetry via VPC Flow Logs.

## [AWS Edge Security & Perimeter Defense](https://docs.aws.amazon.com/waf/)
- [ ] Defend application layer workloads from SQL injection and cross-site scripting using AWS WAF Web ACLs.
- [ ] Deploy [AWS Shield Advanced](https://docs.aws.amazon.com/shield/) to mitigate volumetric DDoS threat vectors.
- [ ] Secure hybrid connections with [AWS Site-to-Site VPN](https://docs.aws.amazon.com/vpn/) and [AWS Direct Connect](https://docs.aws.amazon.com/directconnect/).
- [ ] Implement managed detection utilizing [Amazon GuardDuty](https://docs.aws.amazon.com/guardduty/) and data classification via [Amazon Macie](https://docs.aws.amazon.com/macie/).

## [AWS KMS & Data Encryption](https://docs.aws.amazon.com/kms/)
- [ ] Implement encryption-at-rest across data planes utilizing Customer Managed Keys (CMKs) vs AWS Managed Keys.
- [ ] Define explicit resource access controls via KMS Key Policies.
- [ ] Automate envelope encryption workflows alongside scheduled key rotation routines.
- [ ] Provision encryption-in-transit certificates using [AWS Certificate Manager (ACM)](https://docs.aws.amazon.com/acm/) tied to TLS endpoints.
