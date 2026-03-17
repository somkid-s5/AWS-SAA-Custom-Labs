# AWS SAA Custom Labs

Hands-on lab roadmap for AWS Certified Solutions Architect – Associate (SAA-C03).

## Repository Structure
```
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

## Lab Catalog (25 Labs)
- 00 IAM Basics & Least Privilege
- 01 Build a VPC from Scratch
- 02 Security Groups vs NACLs
- 03 S3 Encryption & Lifecycle
- 04 EBS vs EFS vs Instance Store
- 05 RDS Multi-AZ vs Read Replica
- 06 ALB + Auto Scaling
- 07 Serverless CRUD API
- 08 NAT Gateway Patterns
- 09 VPC Endpoints
- 10 VPC Peering vs Transit Gateway
- 11 Route 53 Failover Routing
- 12 SNS + SQS + Lambda Fanout
- 13 KMS + Secrets Manager + Parameter Store
- 14 WAF with ALB
- 15 CloudTrail + Config + GuardDuty
- 16 CloudFront + S3 OAC
- 17 ECS Fargate Basics
- 18 ElastiCache for Session Caching
- 19 3-Tier Web Architecture
- 20 Event-Driven Ordering Workflow
- 21 Backup & DR Strategy
- 22 Observability with CloudWatch/X-Ray
- 23 Cost Optimization Workshop
- 24 Multi-Account Landing Zone

## How to Use
1. Start with `docs/study-plan.md`.
2. Complete labs in order, logging lessons learned after each lab.
3. Use the validation and cleanup sections to avoid drift and extra cost.

## Next Enhancements
- Add Terraform IaC variant for each lab.
- Add solution architecture PNG diagrams under `assets/diagrams/`.
- Add quizzes and answer keys per lab.
