# AWS SAA-C03 Custom Labs

> **25 Hands-on Labs** สำหรับเตรียมสอบ AWS Solutions Architect Associate (SAA-C03)
> ทุก Lab มี Business Scenario, CLI + Console Steps, Failure Injection, Exam Questions และ Cleanup

---

## ⚡ Quick Start

```bash
# 1. ทำ Lab 01 ก่อนเสมอ (สร้าง VPC Foundation ที่ Labs อื่นใช้ร่วม)
cd labs && cat 01-vpc-from-scratch.md

# 2. ดู Environment Setup ที่ต้นแต่ละ Lab แล้ว export ตัวแปรก่อนรัน
export AWS_REGION=ap-southeast-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 3. Run Cleanup หลังทำแต่ละ Lab เสมอ
```

---

## 📚 Study Path Recommendations

### 🟢 Path A — Beginner (ไม่เคยใช้ AWS มาก่อน | ~4 สัปดาห์)

| สัปดาห์ | Labs | หัวข้อ |
|---|---|---|
| Week 1 | Lab 00 → 01 → 02 → 03 → 04 | IAM, VPC Basics, Storage |
| Week 2 | Lab 05 → 06 → 07 → 08 → 09 | Database, ALB/ASG, Serverless, Network |
| Week 3 | Lab 11 → 12 → 13 → 16 → 22 | DNS, Messaging, Security, CDN, Monitoring |
| Week 4 | Mock Exams + Review ตาม Weak Areas | — |

> **หมายเหตุ:** ข้ามข้าม Lab 10, 14, 15, 17-21, 23-24 ก่อน — รอสัปดาห์ 4

---

### 🟡 Path B — Intermediate (มีประสบการณ์ AWS บ้างแล้ว | ~2 สัปดาห์)

| สัปดาห์ | Labs | หัวข้อ |
|---|---|---|
| Week 1 | Lab 10 → 14 → 15 → 17 → 18 → 19 | Advanced Network, Security, Containers, 3-Tier |
| Week 2 | Lab 20 → 21 → 23 → 24 + Mock Exams | Event-driven, DR, Cost, Multi-Account |

> เริ่มจาก Lab 01 ก่อน 1 ครั้ง เพื่อสร้าง VPC ที่ Labs อื่นใช้ร่วม

---

### 🔴 Path C — Exam Cram (สอบใน 2 สัปดาห์)

**Focus Labs:** 00, 01, 05, 06, 07, 12, 14, 19, 21

- Lab 00 — IAM (ออกสอบทุกครั้ง)
- Lab 01 — VPC Design (ออกสอบทุกครั้ง)
- Lab 05 — RDS Multi-AZ vs Replica (RTO/RPO)
- Lab 06 — ALB + ASG (Scalability)
- Lab 07 — Lambda + DynamoDB (Serverless)
- Lab 12 — SNS + SQS DLQ (Decoupling)
- Lab 14 — WAF + Shield (Security)
- Lab 19 — 3-Tier Architecture (Integration)
- Lab 21 — Backup & DR Strategies

---

## 🔗 Lab Dependencies

```
Lab 00 (IAM) ─────────────────────────────── ไม่มี Dependency
Lab 01 (VPC) ─────────────────────────────── ไม่มี Dependency
                ├── Lab 02 (SG/NACL)
                ├── Lab 05 (RDS)           ← ต้องมี Isolated-Subnet ×2
                ├── Lab 06 (ALB/ASG)       ← ต้องมี Public-Subnet ×2
                ├── Lab 08 (NAT)           ← ต้องมี Private-Subnet ×2
                └── Lab 09 (VPC Endpoints) ← ต้องมี Private-Subnet

Labs 03, 04, 07, 10-24 ─────────────────── สร้าง Resources ของตัวเอง
```

> ⚠️ **คำเตือน Cleanup:** ห้ามลบ VPC จาก Lab 01 จนกว่าจะทำ Labs 02, 05, 06, 08, 09 เสร็จทั้งหมด
> ใช้ `scripts/cleanup-all-labs.sh` เพื่อลบตามลำดับที่ถูกต้อง

---

## 📋 Lab Index

| # | Lab | Topic | Difficulty | Cost | ใช้ Lab 01 VPC? |
|---|---|---|---|---|---|
| 00 | [IAM Basics](labs/00-iam-basics.md) | IAM, Policies, MFA | Beginner | Free | ❌ |
| 01 | [VPC from Scratch](labs/01-vpc-from-scratch.md) | VPC, Subnets 2-AZ, IGW | Intermediate | Free | — |
| 02 | [SG vs NACLs](labs/02-security-groups-vs-nacls.md) | Stateful vs Stateless | Intermediate | Free | ✅ |
| 03 | [S3 + Lifecycle](labs/03-s3-encryption-lifecycle.md) | Encryption, Lifecycle | Intermediate | Free | ❌ |
| 04 | [EBS/EFS/Instance Store](labs/04-ebs-efs-instance-store.md) | Storage Trade-offs | Intermediate | Free | ✅ |
| 05 | [RDS Multi-AZ](labs/05-rds-multi-az-read-replica.md) | HA vs Read Scaling | Advanced | ~$1-3 | ✅ |
| 06 | [ALB + ASG](labs/06-alb-asg-high-availability.md) | Stateless Web Tier | Intermediate | ~$0.50 | ✅ |
| 07 | [Lambda + DynamoDB](labs/07-lambda-api-gateway-dynamodb.md) | Serverless CRUD API | Intermediate | Free | ❌ |
| 08 | [NAT Gateway](labs/08-nat-gateway-private-subnets.md) | Private Egress | Intermediate | ~$0.20 | ✅ |
| 09 | [VPC Endpoints](labs/09-vpc-endpoints.md) | Private AWS Access | Intermediate | Free | ✅ |
| 10 | [Peering vs TGW](labs/10-vpc-peering-vs-transit-gateway.md) | Multi-VPC Connect | Advanced | ~$1.20 | ❌ |
| 11 | [Route 53 Failover](labs/11-route53-failover.md) | DNS-based DR | Intermediate | Free | ❌ ⚠️ Domain |
| 12 | [SNS + SQS + Lambda](labs/12-sns-sqs-lambda.md) | Fanout + DLQ | Intermediate | Free | ❌ |
| 13 | [KMS + Secrets](labs/13-kms-secrets-parameter-store.md) | Secret Management | Intermediate | Free | ❌ |
| 14 | [WAF + Shield](labs/14-waf-alb-shield.md) | L7 Protection | Advanced | ~$5/mo | ❌ |
| 15 | [CloudTrail + GuardDuty](labs/15-cloudtrail-config-guardduty.md) | Governance | Intermediate | Free | ❌ |
| 16 | [CloudFront + S3 OAC](labs/16-cloudfront-s3-oac.md) | Static CDN Delivery | Intermediate | Free | ❌ |
| 17 | [ECS Fargate](labs/17-ecs-fargate-basics.md) | Serverless Containers | Intermediate | Free | ❌ |
| 18 | [ElastiCache](labs/18-elasticache-session-store.md) | Session Store | Intermediate | ~$0.20 | ❌ |
| 19 | [3-Tier Architecture](labs/19-3tier-reference-architecture.md) | End-to-End Web App | Advanced | ~$2.50 | ❌ |
| 20 | [Event-Driven Orders](labs/20-serverless-event-driven-ordering.md) | Async Fanout | Intermediate | Free | ❌ |
| 21 | [Backup & DR](labs/21-backup-dr-strategy.md) | Recovery Planning | Intermediate | Free | ❌ |
| 22 | [Observability](labs/22-observability-cloudwatch-xray.md) | Metrics, Logs, Traces | Intermediate | Free | ❌ |
| 23 | [Cost Optimization](labs/23-cost-optimization-lab.md) | Spend Reduction | Intermediate | Free | ❌ |
| 24 | [Multi-Account LZ](labs/24-multi-account-landing-zone.md) | Org Guardrails | Advanced | Free | ❌ |

---

## 🧹 Cleanup

### ลบ Resources ทั้งหมดในครั้งเดียว

```bash
# วิธีที่ 1: ใช้ cleanup script (แนะนำ — จัดการ Dependencies อัตโนมัติ)
bash scripts/cleanup-all-labs.sh

# วิธีที่ 2: ลบทีละ Lab ตาม Cleanup Section ในแต่ละไฟล์
```

### ตรวจสอบค่าใช้จ่ายที่อาจค้างอยู่

```bash
# Resources ที่มีค่าใช้จ่ายรายชั่วโมงที่ต้องตรวจก่อน
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available" \
  --query 'NatGateways[*].{ID:NatGatewayId,VPC:VpcId}' --output table

aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].{Name:LoadBalancerName,State:State.Code}' --output table

aws rds describe-db-instances \
  --query 'DBInstances[*].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}' --output table
```

---

## 📁 Repository Structure

```
AWS-SAA-Custom-Labs/
├── labs/           # 25 Lab markdown files (00–24)
├── scripts/        # Automation scripts
│   └── cleanup-all-labs.sh
├── docs/           # Supporting guides
└── README.md
```

---

## 🔗 Useful Links

- [AWS Pricing Calculator](https://calculator.aws/)
- [AWS SAA-C03 Exam Guide](https://d1.awsstatic.com/training-and-certification/docs-sa-assoc/AWS-Certified-Solutions-Architect-Associate_Exam-Guide.pdf)
- [Lab Writing Standard](docs/lab-writing-standard.md)
