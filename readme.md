# Fairview – Isolated Recovery Environment (IRE) on AWS

## Chapter 1 — Recovery Flow

**Step 1:** A cyber attack occurs. Production is no longer trusted. Nothing inside production can be assumed safe.

**Step 2:** Administrators do not log into production. Instead... They enter the Recovery Access environment. This becomes the secure front door.

**Step 3:** From there, they enter the Core Recovery environment. Think of this as mission control. Nothing sensitive lives here. Instead it contains the tools needed to recover: Automation, Validation, Management, Directory Services, DNS, Logging, Monitoring.

**Step 4:** Separately, the Protected Data environment stores the workloads that are eventually restored. Databases, File systems, Application storage. This is where recovered data lives.

**Step 5:** Meanwhile, recovery content is coming from two completely different places. This is the most important concept in the whole diagram.

- **Recovery Artifacts** contains Infrastructure.
  Examples: Terraform and Ansible playbooks, Golden AMIs, Recovery Runbooks, Scripts, Container images. These tell AWS how to rebuild.
- **Workload Backups** contains Data.
  Examples: Oracle, SQL, File Shares, VM backups, Application backups. These contain what to restore.

These are **NOT** the same thing. The diagram intentionally separates them because they have different lifecycles, storage mechanisms, and validation processes.

**Step 6:** Nothing gets restored immediately. Everything passes through validation. This includes:

`Malware scan` → `Integrity verification` → `Human approval` → `Promotion` (Only then is it trusted.)

**Step 7:** Recovery begins. Infrastructure comes online. Applications start and Data is restored. Users reconnect and production resumes.

### Why Three VPCs?

Each VPC has one responsibility:

- **Recovery Access VPC:** Secure entry point. Administrative access only. No workload data.
- **Core Recovery VPC:** Recovery tooling, Automation, Orchestration, Validation, Platform services.
- **Protected Data VPC:** Restored databases, Restored file systems, Restored applications, Sensitive recovered data.

By separating these roles, we are basically reducing the blast radius of any compromise and enforce clear trust boundaries.

---

## Chapter 2 — Architectural Layers

Before we discuss each AWS service, think of the architecture as layers, not services.

```
┌──────────────────────────────────────────────────────────┐
│ Account-Level Security & Monitoring                      │
├──────────────────────────────────────────────────────────┤
│ Administrative Access                                    │
├──────────────────────────────────────────────────────────┤
│ Recovery Platform                                        │
├──────────────────────────────────────────────────────────┤
│ Protected Workloads                                      │
├──────────────────────────────────────────────────────────┤
│ Backup & Recovery Storage                                │
├──────────────────────────────────────────────────────────┤
│ Recovery Artifacts                                       │
└──────────────────────────────────────────────────────────┘
```

Every AWS service belongs to one of these layers.

### 1. Account-Level Services (Not in Any VPC)

These are often misunderstood because they don't "live" inside subnets. They operate at the AWS account or Region level.

- **CloudTrail:** Records every AWS API call. Who deleted an EC2 instance? Who changed a Security Group? Who modified a KMS key?
  *Why isn't it inside a VPC?* CloudTrail records control plane activity across the account. It isn't tied to a network interface.

- **AWS Config:** Maintains a history of your AWS resource configurations. Example configuration changes for every resource in AWS, like security group changes, AMI revision changes, etc.
  *Why not inside a VPC?* It monitors AWS resources, not network traffic.

- **GuardDuty:** Continuously analyzes AWS activity for suspicious behavior. Example: Stolen credentials, Crypto mining, Unusual API activity, Malware findings, DNS anomalies.
  *Why account-level?* It consumes logs from CloudTrail, VPC Flow Logs, DNS logs, EKS, S3, and more. It's not tied to one subnet.

- **Security Hub:** The central security dashboard. It aggregates findings from: GuardDuty, Config, Inspector, IAM Access Analyzer. It's basically the SOC Dashboard.

- **CloudWatch:** Monitoring.
  *Why not in a VPC?* CloudWatch is a managed service. EC2 instances send telemetry to it.

- **Log Archive:** Long-term log retention. Usually backed by an S3 bucket with lifecycle policies and immutability.

### 2. Recovery Access VPC

Think of this as the front door. Nothing sensitive is stored here. Only administrative access.

- **AWS Client VPN:** Secure administrator entry. Instead of exposing SSH or RDP publicly, administrators connect through the VPN.
- **VPN Association ENIs:** These are created automatically when you associate the Client VPN endpoint with subnets. They inject VPN traffic into the Recovery Access VPC.
- **Break Glass Workstation:** Emergency administrative workstation. Only used when normal access paths fail.
- **SSM Interface Endpoint:** Allows Systems Manager traffic without Internet access. Your EC2 instances communicate with SSM privately.
  *Why in endpoint subnets?* Interface endpoints are ENIs (Elastic Network Interfaces). They must exist inside a subnet. Remove it and SSM won't work in an isolated environment.
- **Secrets Manager Endpoint:** Private access to Secrets Manager (without internet).
- **KMS Endpoint:** Private communication with AWS KMS (without Internet).
- **CloudWatch Logs Endpoint:** Allows private log delivery.

### 3. Core Recovery VPC

This is the brain. No recovered business data. Just recovery infrastructure.

- **Internal ALB:** Internal application load balancing. Only internal traffic. Nothing should be Internet-facing.
- **AWS WAF:** Protects web applications.
  *Architectural observation:* If the ALB is purely internal, WAF may not provide much value. If this layer later fronts a recovery portal or API, it makes more sense.
- **Managed Active Directory:** Provides authentication for recovery workloads. Most importantly: this is not production Active Directory, since Production AD cannot be trusted after a cyberattack.
- **Route 53 Resolver Endpoint:** DNS resolution. Allows private DNS queries between environments.
- **Ansible Server / Terraform:** Our orchestration is AAP, which is a SaaS product that runs on RedHat Cloud and then connects to our org using Site-Site VPN and then assumes role in our AWS sandbox account — so why need Ansible or Terraform here?
- **Restore Servers:** Orchestrate restore jobs. Receive recovered data. Coordinate restores.
- **Validation Servers:** Verify restored data. Run health checks. Run application validation.
- **Jump Hosts:** Controlled administrative access.
  *Architectural observation:* Since you already use Client VPN and Systems Manager, these may become optional over time.
- **Tooling / Utilities:** Supporting scripts and operational tooling.
- **Amazon ECR Endpoint:** Private access to container images.
- **SSM Endpoint:** Private Systems Manager communication.
- **S3 Gateway Endpoint:** Private S3 access. Notice this is a Gateway Endpoint, not an Interface Endpoint, because S3 works differently.

### 4. Protected Data VPC

This is where recovered business systems live.

Recovered databases. Recovered relational databases. Recovered Windows file systems. Recovered Linux shared storage. Aurora, RDS, Amazon FSx, Amazon EFS.

- **Malware Compute:** Malware scanning. This deserves its own chapter because it's closely tied to the Recovery Validation Pipeline.
- **Integrity Validation Compute:** Checksum validation. Application testing. Data integrity verification. — Since we are using AAP which performs health checks, why need a separate compute?
- **Endpoint Subnets:** Again SSM, Logs, KMS, Gateway Endpoint — these are private service access points.

### 5. AWS Network Firewall

This is the only component I'd currently mark as architecturally unresolved.

### 6. Recovery Artifact Repository

This stores instructions, not business data.

- Terraform modules
- Golden AMIs
- Ansible collections
- Container images
- Runbooks

Think of it as the recipe book for rebuilding the environment.

- **S3 Object Lock:** Immutable storage for recovery artifacts. Nothing here should change after approval. (WORM)
- **Amazon ECR:** Stores immutable container images.
- **Golden AMIs:** Pre-approved machine images.

### 7. AWS Backup

This stores business data, not infrastructure definitions. It is completely separate from the Recovery Artifact Repository.

- **Standard Backup Vault:** Operational backup storage.
- **Backup Plan:** Defines backup schedules and retention.
- **Backup Selection:** Defines which resources are protected.
- **Backup Copy:** Copies backups to another vault.
- **Logically Air-Gapped Vault:** Immutable backup storage. Even administrators cannot immediately delete these recovery points.

### 8. Recovery Content Lifecycle

This is a workflow, not a storage system. Nothing is "stored" here; it describes how recovery artifacts become trusted.
