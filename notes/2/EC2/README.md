# EC2 - Elastic Compute Cloud

## Virtualization

| Type | Description |
|------|-------------|
| **Emulated** | VM with allocated resources and its own emulated "fake" resources. Guest OS operates with help of Hypervisor doing binary translation. Not efficient and slow. |
| **Para-virtualization** | Modifies parts of the VM's OS to call the hypervisor directly (hypercalls). |
| **Hardware Assisted** | Hardware is aware of virtualization. Accepts Guest OS calls but routes them to the hypervisor. Network & Disk IO still consumed quickly. |
| **SR-IOV** | Single Route IO Virtualization — NIC presents itself as smaller "real" cards, no translation from hypervisor needed. Guest OS can access directly. In EC2, this is called **Enhanced Networking**. |

---

## Architecture

- Instances are VMs on shared or dedicated hosts (AWS managed, isolated from each other)
- 1 host per 1 AZ
- **Storage**: EBS
- **Data network**: ENI is created from instance to subnet; can map to multiple subnets
- Cannot connect across AZs with instances or EBS volumes

---

## Storage

### Performance Formula

```
IO (block) size  x  IOPS (IO/s)  =  Throughput
```

---

## EBS - Elastic Block Store

- Can be encrypted with KMS
- Instances see block devices and create a file system on top
- Storage provisioned in 1 AZ (resilient within that AZ)
- Not linked to instance lifecycle
- Can snapshot into S3 (regionally resilient) and use to recreate in another AZ

### Volume Types

| Type | Name | Notes |
|------|------|-------|
| **GP2** | General Purpose SSD | Default general use |
| **GP3** | General Purpose SSD v3 | Improved baseline, independent IOPS/throughput |
| **IO1/IO2** | Provisioned IOPS SSD | Maximum consistent IOPS, data-critical workloads. Supports **Multi-Attach** (multiple instances) |
| **ST1** | Throughput Optimized HDD | Sequential IO, throughput & economy priority. Cannot be boot volume. |
| **SC1** | Cold HDD | Maximum economy, lowest performance priority. Cannot be boot volume. |

> **IO1/IO2**: Use when maximum consistent IOPS is a priority and data is important. Allows specifying IOPS independent of volume size.

---

## EBS Snapshots

- Incremental volume copies to S3 (similar to git history)
- Used for cloning volumes or moving EBS between AZs/regions
- Volumes restore **lazily** — reads can pull from S3 if data not yet transferred
- Run `dd` on Linux to force EBS to fetch all data immediately for production performance
- **Fast Snapshot Restore (FSR)**: Immediately restores without the lazy load; costs extra. Limit of 50 per region.
- Billing is based on data stored, not snapshot frequency

### Encryption

- No encryption at rest by default; can set a default KMS key
- Each volume gets a unique DEK; snapshots use the same DEK as the source volume
- Cannot revert back to unencrypted
- OS is unaware of encryption (no performance impact)

---

## Instance Store Volumes

- Block storage physically connected to 1 EC2 host
- Instances on that host can access — offer **highest performance**
- Must be attached at launch
- **Ephemeral**: data is lost if instance moves between hosts (stop/start, maintenance)
- Included in instance pricing

**Use cases**: replaceable data, temporary data, maximum IO

---

## Network Interfaces, IPs, and DNS

- **ENI** (Elastic Network Interface): virtual network card attached to instance

---

## AMI - Amazon Machine Image

- Snapshot/image of an instance used to create new EC2 instances
- Can be AWS-provided, community, or custom
- Regionally unique
- Lifecycle: AMI → Launch → Running → Stop → Snapshot → New AMI

---

## EC2 Instance States

| State | Description |
|-------|-------------|
| **Running** | Instance is active |
| **Stopped** | Instance is off; EBS data persists |
| **Terminated** | Instance is deleted |

---

## Billing Models

| Model | Use Case |
|-------|----------|
| **On-Demand** | Short-term, unpredictable, or interruption-intolerant workloads |
| **Reserved** | Long-term, steady-state workloads (cheaper than on-demand) |
| **Spot** | Cheapest option; can be interrupted |

---

## Section Quiz

**Q1: What are the three main states of EC2 instances?**
> Running, Stopped, Terminated

**Q2: What is true of instance store volumes?**
> They are temporary (ephemeral) storage; data can be lost on stop/start or hardware failure

**Q3: If the AZ an EC2 instance is in fails, what happens?**
> The instance will remain failed until at least when the AZ recovers

**Q4: Can an EC2 instance be migrated between AZs?**
> No — but an AMI can be created from an instance and used to provision a clone in another AZ

**Q5: What use-case suits IO1 EBS volumes?**
> When maximum consistent IOPS is a priority and data is important

**Q6: Which volume type lets you specify IOPS independent of volume size?**
> IO1

**Q7: How many instances can a GP2 volume be attached to simultaneously?**
> 1

**Q8: Can EBS volumes be attached to instances in any AZ?**
> No — only instances in the same AZ as the volume

**Q9: When should instance store volumes be used?**
> For replaceable data, temporary data, or maximum IO

**Q10: Short-term workload needing cheapest EC2 pricing but cannot tolerate interruption — which billing model?**
> On-Demand