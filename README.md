# AWS-SAA-Custom-Labs (Full Detailed Version)

ชุดแลปเตรียมสอบ **AWS Certified Solutions Architect – Associate (SAA-C03)** แบบลงมือทำจริง เน้นเหตุผลเชิงสถาปัตยกรรม + หลักฐานการทดสอบ + มุมมอง production readiness

## เป้าหมายของ Repo นี้
- เปลี่ยนจาก “อ่านทฤษฎี” เป็น “ออกแบบ + ลงมือทำ + พิสูจน์ผล”
- ฝึกตัดสินใจภายใต้ข้อจำกัดจริง: Security, Availability, Performance, Cost
- สร้างพอร์ตงานที่อธิบายได้ทั้งเชิงเทคนิคและเชิงธุรกิจ

## โครงสร้าง
```text
AWS-SAA-Custom-Labs/
├─ README.md
├─ docs/
│  ├─ study-plan.md
│  ├─ exam-tips.md
│  └─ cost-notes.md
├─ labs/
│  ├─ 00-iam-basics.md
│  ├─ 01-vpc-from-scratch.md
│  ├─ ...
│  └─ 24-multi-account-landing-zone.md
└─ assets/
   └─ diagrams/
```

## Lab Roadmap (25 Labs)
### Foundation + Security
- 00 IAM Foundations, Least Privilege, Cross-Account
- 01 Production-Ready VPC from Scratch
- 02 Security Groups vs NACLs
- 03 S3 Security + Encryption + Lifecycle
- 04 EBS vs EFS vs Instance Store

### Data + Compute + Scaling
- 05 RDS Multi-AZ vs Read Replica
- 06 ALB + Auto Scaling High Availability
- 07 Serverless CRUD API (API Gateway/Lambda/DynamoDB)
- 08 NAT Gateway Patterns
- 09 VPC Endpoints

### Connectivity + Reliability
- 10 VPC Peering vs Transit Gateway
- 11 Route 53 Failover
- 12 SNS + SQS + Lambda Fanout
- 13 KMS + Secrets Manager + Parameter Store
- 14 WAF + ALB + Shield

### Governance + Delivery
- 15 CloudTrail + Config + GuardDuty
- 16 CloudFront + S3 OAC
- 17 ECS Fargate Basics
- 18 ElastiCache Session Store
- 19 3-Tier Reference Architecture

### Advanced Architecture Thinking
- 20 Event-Driven Ordering Workflow
- 21 Backup + DR Strategy
- 22 Observability (CloudWatch + X-Ray)
- 23 Cost Optimization Deep Dive
- 24 Multi-Account Landing Zone

## วิธีใช้ให้ได้ผลจริง
1. เริ่มจาก `docs/study-plan.md` เพื่อกำหนด cadence รายสัปดาห์
2. ทำแลปตามลำดับ และบันทึก “เหตุผลการเลือกบริการ” ทุกครั้ง
3. ทุกแลปต้องมี 3 อย่าง: functional test, failure test, cleanup evidence
4. ก่อนจบแต่ละแลป ให้ตอบ exam-style questions ด้วยภาษาของตัวเอง

## Definition of Done ต่อ 1 Lab
- ทำครบทุก phase
- มีหลักฐานจาก metrics/logs/screenshot
- สรุป trade-off อย่างน้อย 2 ทางเลือก
- cleanup เสร็จและยืนยันต้นทุนไม่วิ่งต่อ

## แผนพัฒนาต่อ
- เพิ่ม Terraform เวอร์ชันเต็มต่อแลป
- เพิ่มภาพสถาปัตยกรรม PNG ใน `assets/diagrams/`
- เพิ่ม mock questions + answer rationale ต่อหัวข้อ
