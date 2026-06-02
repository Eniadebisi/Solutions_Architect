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

### Aurora (AWS engine — differs from above)
- **Shared storage volume** (6 copies across 3 AZs), not local EBS per instance.
- Replication at the **storage layer**; replicas read the same volume.
- Up to **15** dedicated read replicas (vs 2 in Multi-AZ DB cluster).
- Engines: **Aurora MySQL / PostgreSQL**.
- Failover typically faster, lower replica lag.

### Cluster Endpoints (RDS Multi-AZ DB cluster *and* Aurora)
- **Cluster** → writer; used for reads, writes, administration.
- **Reader** → any available reader instance.
- **Instance** → a specific instance; generally for testing / fault finding.
- **Custom** → user-defined subset of instances — **Aurora only**.

## Backups
- **Snapshot = full instance** (not just one DB) → S3.
- First snapshot **FULL** (size of consumed data); onward **incremental**.
- Automated backups + manual snapshots → **AWS-managed S3 buckets**.
- Transaction logs every **5 min**.
- Retention **0–35 days**.
- RDS can replicate backups / snapshots / logs to **another region**.

### Restores
- Always **creates a new RDS instance**.
- Restore points: snapshot creation time, or automated **any 5-min point in time**.
- Backup restored + transaction logs **replayed** → restores are **not fast**.

### Replication summary
- **Synchronous** → standby (Multi-AZ).
- **Asynchronous** → read replicas (can be **cross-region**).
- Read replicas: near-zero RPO, low RTO — but do **not** protect against data corruption.

## Learning Objectives

- [ ] Mitigate read-intensive workload constraints by scaling out asynchronous Read Replicas.
- [ ] Implement [Amazon RDS Proxy](https://docs.aws.amazon.com/rds/proxy/) pools to optimize application connection scaling limits.
- [ ] Design ultra-low-latency distributed configurations using Aurora Global Databases.
