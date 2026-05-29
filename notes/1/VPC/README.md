# VPC (Virtual Private Cloud)

## IP Addressing

- VPC size: min `/28`, max `/16`
- Avoid common ranges (e.g. `10.0.0.0/8` conflicts with many corporate networks)
- Plan your range by estimating the highest number of AWS regions you might use, plus room to grow
- Each subnet reserves **5 IP addresses** (network, VPC router, DNS, future use, broadcast)

## Default vs Custom VPC

- Each region has **1 default VPC**, but can have **many custom VPCs**
- Default VPC: fixed scheme, beginner-friendly, some services behave oddly if it doesn't exist
- Custom VPC: flexible network configuration
- Default VPCs can be recreated (no support ticket needed)

## Tenancy

- **Default (Shared):** hardware shared with other AWS customers — cheaper
- **Dedicated:** hardware reserved for you — cannot be changed after set on children hosts

## Stateful vs Stateless Firewalls

### Stateless
- Treats request and response as separate, unrelated connections
- Requires explicit inbound **and** outbound rules for every connection
- Responses come back on **ephemeral ports** (random high ports) — you must open all of them outbound, for any IP
- Example: **NACLs**

### Stateful
- Understands that a response belongs to a request
- Allowing a request **automatically allows the response** — no extra rule needed
- Example: **Security Groups**

## NACLs (Network Access Control Lists)

- **Stateless** — request and response rules needed separately
- Default NACL: rule 100 allow all, implicit deny — beginner friendly
- Custom NACL: default deny everything
- A subnet can only have **1 NACL**; a NACL can be associated with **many subnets**
- Applied at the **subnet level** — cannot be assigned directly to AWS resources
- Can explicitly **ALLOW and DENY** — useful for blocking specific bad actor IPs/ranges

## Security Groups (SG)

- **Stateful** — response traffic automatically allowed
- Can only **ALLOW** — no explicit deny rules
- Cannot block specific IPs (use NACLs for that)
- Support IP/CIDR ranges **and** logical resources (other SGs)

## Internet Gateway (IGW)

- Connects your VPC to the internet
- **Highly available by default** — no configuration needed, attached at the VPC level
- One IGW per VPC

## Route Tables

- A subnet can have **one route table** attached
- A route table can be associated with **many subnets**

## NAT Gateway

- Allows **IPv4 private instances** to initiate outgoing internet traffic
- Private IPs masquerade as the NAT Gateway's public Elastic IP
- Runs from a **public subnet**
- **AZ-scoped** — for resilience, deploy one NAT Gateway per AZ

## Quick Reference: SG vs NACL

| | Security Group | NACL |
|---|---|---|
| Level | Resource | Subnet |
| Stateful | Yes | No |
| Allow rules | Yes | Yes |
| Deny rules | No | Yes |
| Rule evaluation | All rules | In order, stops at first match |

---

## Section Quiz

<details>
<summary>1. What does a VPC provide?</summary>

An **Isolated Network** within AWS for your resources.

</details>

<details>
<summary>2. What is true about default and custom VPCs?</summary>

- Each region gets **1 default VPC** and can have many custom VPCs
- Custom VPCs offer flexible network configuration
- Some AWS services behave oddly if the default VPC doesn't exist
- The default VPC can be recreated without a support ticket

</details>

<details>
<summary>3. What is the maximum and minimum size of a VPC?</summary>

- Max: `/16`
- Min: `/28`

</details>

<details>
<summary>4. What is the maximum and minimum size of a subnet?</summary>

- Max: `/16`
- Min: `/28`

</details>

<details>
<summary>5. What is the relationship between AZs and subnets?</summary>

An AZ can have **many subnets**, but a subnet belongs to **one AZ** only.

</details>

<details>
<summary>6. How many IP addresses are reserved per subnet, and why?</summary>

**5 IPs** are reserved per subnet:
1. Network address
2. VPC router
3. DNS
4. Future use
5. Broadcast

</details>

<details>
<summary>7. What is true about the Internet Gateway (IGW)?</summary>

The IGW is **highly available by default** — it is attached at the VPC level with no additional configuration required. One IGW per VPC.

</details>

<details>
<summary>8. What is the difference between Security Groups and NACLs in terms of allow/deny?</summary>

- **Security Groups**: can only **ALLOW** — no explicit deny
- **NACLs**: can both **ALLOW and DENY** — useful for blocking specific IPs or ranges

</details>

<details>
<summary>9. What does NAT provide and what traffic does it support?</summary>

NAT allows **IPv4 private instances** to initiate outgoing internet traffic. Private IPs are masqueraded behind the NAT Gateway's public Elastic IP. It does **not** support inbound connections initiated from the internet.

</details>

<details>
<summary>10. What is the relationship between subnets and route tables?</summary>

- A subnet can have **one route table** attached
- A route table can be associated with **many subnets**

</details>