# RDS & Aurora

## Database Models

### CAP Theorem
- **C**onsistency, **A**vailability, **P**artition tolerance (resilience) — pick **2**.

### ACID — relational (RDS), limits scaling
- **Atomic** — ALL or NO components of a transaction succeed/fail.
- **Consistent** — transactions move DB from one valid state to another; nothing in-between.
- **Isolated** — concurrent transactions don't interfere; each runs as if it's the only one.
- **Durable** — once committed, stored on non-volatile memory; survives power loss/crashes.

### BASE — NoSQL (DynamoDB)
- **Basically Available** — read/write available "as much as possible", no consistency guarantees.
- **Soft State** — DB doesn't enforce consistency; offloaded to the application/user.
- **Eventually Consistent** — wait long enough and reads become consistent.

---

## Architecture
- DBaaS: managed, can run multiple DB instances, choice of engine, **no OS/SSH access** (RDS **Custom** does grant OS access).
- **Amazon Aurora** — AWS's own engine.
- Storage: dedicated **EBS** per instance.
- **Subnet Group** — defines which subnets RDS can use.
- Access: from VPC or connected private networks (VPN / Direct Connect); can also be given **public addressing** for internet access.

### Multi-AZ Instance Mode
- Standby in another AZ, **synchronous** replication.
- Failover **60–120s**.

### Multi-AZ DB Cluster (standard RDS — *not* Aurora)
- **1 Writer + exactly 2 Readers**; readers also serve as failover targets.
- Engines: **MySQL / PostgreSQL only**.
- Local **EBS** storage per instance; replication via **transaction logs** (semi-sync).
- Writes committed when **≥1 reader** confirms.
- Failover **~35s** (faster than instance mode).

### Cluster Endpoints (RDS Multi-AZ DB cluster *and* Aurora)
- **Cluster** → writer; used for reads, writes, administration.
- **Reader** → any available reader instance.
- **Instance** → a specific instance; generally for testing / fault finding.
- **Custom** → user-defined subset of instances — **Aurora only**.

---

## Security

### Encryption in Transit
- **SSL/TLS** between client and RDS host — can be set to **mandatory**.

### Encryption at Rest (EBS)
- **KMS** (CMK or AWS-managed) generates a **DEK** for storage, logs, snapshots, and replicas.
- Encryption **cannot be removed** once enabled.
- **MSSQL** and **Oracle** additionally support **TDE** (Transparent Data Encryption) — encryption within the engine rather than at the host layer (less implicit trust in the host).
- **Oracle** supports **CloudHSM** for stronger key control — keys managed by the user, not AWS.

---

## IAM Authentication
- IAM policy attached to users or roles maps an IAM identity to a local RDS database user.
- **Authentication only** — authorization is still handled by the DB engine itself.

---

## RDS Custom
- Allows RDS with OS-level customization — useful when you need to run your own DB configuration as if on EC2.
- Supports **SSH**, **RDP**, and **Session Manager** access to the underlying instance.

---

## Aurora

### Cluster Architecture
- **Single primary instance + 0 or more replicas** (all replicas are readable).
- **Shared cluster volume** across all instances — faster provisioning, better availability, and lower replica lag than local-EBS approaches.

### Storage
- **SSD-based**; storage scales automatically based on what's consumed — no pre-selected size.
- **High-water mark billing** (being phased out) — freed space can be reused but historically wasn't reclaimed in billing.
- No free-tier option; **Micro instances not supported**.
- For single-AZ workloads at micro scale, standard RDS may be more economical; beyond that Aurora offers better value.

### Pricing
- **Compute** — hourly charge, billed per second, 10-minute minimum.
- **Storage** — GB-Month consumed + per-request I/O cost.
- **Backups** — 100% of DB size included at no extra charge.

### Restores & Cloning
- **Restore** — creates a **new cluster** (same as standard RDS).
- **Backtrack** — in-place rewind to a previous point in time (no new cluster).
- **Fast Clone** — stores only changes from the original; unchanged data is referenced rather than copied.

### Aurora Serverless
- Auto-scales compute capacity; can **scale to zero and pause** when idle.
- Best for: infrequent, new, variable, unpredictable, dev/test, or multi-tenant workloads.
- Analogous to Fargate for containers.

### Aurora Global Database
- **Global-level replication** from a primary region to up to **5 secondary regions**.

### Aurora Multi-Master
- All instances can handle **writes** — no single writer bottleneck.
- Failover is faster and **non-disruptive** compared to standard Aurora, which must promote a replica to master.

---

## Backups
- **Snapshot = full instance** (not just one DB) → S3.
- First snapshot **FULL** (size of consumed data); subsequent snapshots **incremental**.
- Automated backups + manual snapshots → **AWS-managed S3 buckets**.
- Transaction logs every **5 min**.
- Retention **0–35 days**.
- RDS can replicate backups / snapshots / logs to **another region**.

### Restores
- Always **creates a new RDS instance**.
- Restore to: snapshot creation time, or **any 5-min point in time** (automated backup window).
- Backup restored + transaction logs **replayed** → restores are **not instantaneous**.

### Replication Summary

| Type | Direction | Notes |
|------|-----------|-------|
| **Synchronous** | Primary → Standby (Multi-AZ) | HA failover target |
| **Asynchronous** | Primary → Read Replica | Can be cross-region; near-zero RPO, low RTO |

> Read replicas do **not** protect against data corruption — corrupted writes replicate to all replicas.

---

## Section Quiz

<details>
<summary>1. RDS is designed for what database model?</summary>

**SQL**

</details>

<details>
<summary>2. What feature of RDS allows the system to scale for READS?</summary>

**RDS Read Replicas**

</details>

<details>
<summary>3. Which feature of RDS provides HA functionality?</summary>

**RDS Multi-AZ**

</details>

<details>
<summary>4. How is the standby node of an RDS Multi-AZ accessed?</summary>

**It's only accessed after a failover when it becomes the primary instance.**

> The standby is never directly accessible — it serves no read traffic before promotion.

</details>

<details>
<summary>5. Which AWS product can be used to help move data TO or FROM AWS in a controlled and configurable way?</summary>

**DMS** (Database Migration Service)

</details>

<details>
<summary>6. What type of backup should you take of RDS if you want it to be available for up to 1 year?</summary>

**Manual Snapshot**

> Automated backups max out at 35 days retention. Manual snapshots persist until explicitly deleted.

</details>

<details>
<summary>7. When restoring RDS from a snapshot or backup, is any application reconfiguration required?</summary>

**Yes — a different endpoint address is created when restoring; authentication remains the same.**

</details>

<details>
<summary>8. Which managed SQL database product in AWS supports 3+ AZ resilience?</summary>

**Aurora**

</details>

<details>
<summary>9. Which AWS managed SQL database product horizontally scales and can reduce to 0 and pause when there is no load?</summary>

**Aurora Serverless**

</details>

<details>
<summary>10. What RDS DB product supports HA where all instances can be used for writes?</summary>

**Aurora Multi-Master**

</details>
