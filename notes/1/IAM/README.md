# IAM, Accounts and AWS Organisations - [AWS](https://docs.aws.amazon.com/iam/)

## Policy Documents

Each policy document is made up of statements with the following fields:

| Field | Description |
|-------|-------------|
| **Sid** | Optional description/identifier for the statement |
| **Effect** | `Allow` or `Deny` on the action |
| **Action** | The action being attempted (e.g. `s3:GetObject`) |
| **Resource** | The AWS resources the policy applies to |

### Priority Order

**Explicit Deny > Allow > Default Deny (Implicit)**

> If not explicitly allowed, access is denied.

### Policy Types

- **Inline** — applied to each identity individually. N policies for N accounts. Best for special/one-off access.
- **Managed** — created as its own object then attached to any identity. Best for most cases.

---

## IAM Identities

### Principal
A single person, application, or point of ingress that interacts with AWS.

---

### Users
Identity for **long-term** AWS access (single principal) — people, apps, or service accounts.

- Authenticated via **Username & Password** (console) or **Access Keys** (CLI/apps)
- **Limits**: 5,000 IAM users per account; each user can be in up to 10 groups
- Alternatives: IAM Roles & Identity Federation

---

### Groups
Containers that put users together — **cannot be logged into directly**.

- Can be used in IAM policies but **not resource policies** (groups are not principals)
- 300 groups per account; **no nesting** supported

---

### Roles
Used when the number of principals is unknown or exceeds 5,000, or for temporary access.

- **Not representative** of a specific user — more categorical
- Generates **temporary credentials** via STS (Security Token Service); must be renewed for continued access

#### Trust Policies
Define which identities can assume the role — AWS users, services, anonymous access, or external identity providers (Facebook, Google, etc.)

#### Permission Policies
Checked on each use — define what resources the role can access while assumed.

#### Key Use Cases
- Avoid hardcoding access keys in applications
- Grant temporary access upgrades for existing users
- Allow external accounts (FB/Google/Active Directory) to access AWS through a role
- **Identity Federation**: scales to millions of users without creating IAM credentials — uses existing external accounts mapped to a role
- `sts:AssumeRole` — switches into another role within the AWS organization without logging into another account

---

### Service-Linked Roles
Predefined roles tied to a specific AWS service that allow it to act on other services.

- Created by the service itself, or manually in IAM
- **Cannot be deleted** while still in use
- Example: a user may be granted access to a service that creates roles, even if that user doesn't have direct role-creation permissions

---

## ARN - Amazon Resource Names

Uniquely identify any AWS resource.

```
arn:partition:service:region:account-id:resource-id
arn:partition:service:region:account-id:resource-type/resource-id
arn:partition:service:region:account-id:resource-type:resource-id
```

### Examples

| ARN | Refers to |
|-----|-----------|
| `arn:aws:s3:::catgifs` | The `catgifs` bucket |
| `arn:aws:s3:::catgifs/*` | All objects inside the `catgifs` bucket |

> `*` matches all options. Omitting a field (e.g. region/account-id for S3) means it's not needed — S3 buckets are globally unique so region and account-id are implicit.

---

## AWS Organizations

Hierarchical/reverse-tree structure for managing multiple AWS accounts.

- **Organizational Root** — top-level container holding member & management accounts
- **Organizational Units (OUs)** — nested containers holding accounts or other OUs
- **Management Account** (payer/master) — handles consolidated billing for all member accounts

### Benefits
- **Consolidated billing** — pooled usage can unlock volume discounts and reserved capacity savings
- Favors **IAM Roles** (temporary) over IAM Users (static/permanent)
- Enables **identity federation** for on-premises identities
- **Role switching** from one account into other member accounts

---

## SCP - Service Control Policies

- Act as **permission boundaries** — they only restrict, never grant
- Applied at the OU or account level within an organization
- The effective permissions for an identity = **overlap of identity policies AND SCPs**

### Allow vs Deny List

Where identity policies overlap with the SCP defines what is actually allowed.

---

## Section Quiz

<details>
<summary>1. Is there a limit to the number of IAM users in an AWS account? If so, how many?</summary>

**5,000 per account**

</details>

<details>
<summary>2. Which of the following are features of IAM groups?</summary>

- Admin groupings of IAM users
- Can hold identity permissions

> Groups cannot be used to log in, and cannot be nested.

</details>

<details>
<summary>3. Within AWS policies, what is always the priority?</summary>

**Explicit Deny**

Priority order: Explicit Deny > Allow > Default Deny (Implicit)

</details>

<details>
<summary>4. What is true of an AWS Public Service?</summary>

- Located in the **AWS Public Zone** (not the public internet)
- Anyone can connect, but **permissions are required** to access the service

</details>

<details>
<summary>5. What is true of an AWS Private Service?</summary>

- Located in a **VPC**
- Accessible from the VPC it is located in
- Accessible from other VPCs or on-premises networks **as long as private networking is configured**

</details>

<details>
<summary>6. What is true of Simple Storage Service (S3)?</summary>

- S3 is an **AWS Public Service**
- S3 is an **object storage** system
- Buckets can store an **unlimited** amount of data

</details>

<details>
<summary>7. What is a CloudFormation Logical Resource?</summary>

A resource **defined in a CloudFormation Template** — it represents the desired state before it is actually created.

</details>

<details>
<summary>8. What is a CloudFormation Physical Resource?</summary>

A **physical resource created in an AWS account** by creating a CloudFormation stack — the actual instantiation of a logical resource.

</details>

<details>
<summary>9. What is a simple and correct definition of High Availability?</summary>

**A system which maximises uptime.**

> High Availability is about minimising outage time, not about tolerating failure without disruption (that's Fault Tolerance).

</details>

<details>
<summary>10. Which of the following is a correct definition of a fault tolerant system?</summary>

**A system which allows failure and can continue operating without disruption.**

</details>

<details>
<summary>11. How many DNS root servers exist?</summary>

**13**

</details>

<details>
<summary>12. Who manages the DNS Root Servers?</summary>

**12 Large Organisations** (operating the 13 root server clusters under IANA oversight)

</details>

<details>
<summary>13. Who manages the DNS Root Zone?</summary>

**IANA**

</details>

<details>
<summary>14. Which DNS record type converts a hostname into an IPv4 address?</summary>

**A** record

</details>

<details>
<summary>15. Which DNS record type is used by the root zone to delegate control of .org to the .org registry?</summary>

**NS** (Name Server) record

</details>

<details>
<summary>16. Which type of organisation maintains the zones for a TLD (e.g. .ORG)?</summary>

**Registry**

</details>

<details>
<summary>17. Which type of organisation has relationships with the .org TLD zone manager allowing domain registration?</summary>

**Registrar**

</details>

<details>
<summary>18. How many subnets are in a default VPC?</summary>

**Equal to the number of AZs in the region** the VPC is located in (one subnet per AZ).

</details>

<details>
<summary>19. What is the IP CIDR of a default VPC?</summary>

**172.31.0.0/16**

</details>