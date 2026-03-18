# AWS SAA Custom Labs

This repository contains 25 AWS Solutions Architect Associate practice labs.

What the labs now focus on:
- Topic-specific business scenarios instead of one repeated placeholder.
- Concrete CLI commands, expected output, failure injection, trade-offs, common mistakes, and exam rationale.
- A cleaner separation between shared lab structure and service-specific content.

Quick start:
1. Follow the labs in order from `00` to `24`.
2. Capture the expected output before moving on.
3. Run the failure injection step on purpose and note the observed behavior.
4. Clean up every resource when the lab is done.

Lab index:

| # | Lab | Topic |
| --- | --- | --- |
| 00 | [IAM Foundations](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/00-iam-basics.md) | Least privilege and cross-account access |
| 01 | [VPC from Scratch](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/01-vpc-from-scratch.md) | Public, private, and isolated subnet design |
| 02 | [Security Groups vs NACLs](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/02-security-groups-vs-nacls.md) | Stateful vs stateless filtering |
| 03 | [S3 Encryption + Lifecycle](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/03-s3-encryption-lifecycle.md) | Bucket security and cost control |
| 04 | [EBS, EFS, Instance Store](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/04-ebs-efs-instance-store.md) | Storage selection trade-offs |
| 05 | [RDS Multi-AZ vs Read Replica](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/05-rds-multi-az-read-replica.md) | HA vs read scaling |
| 06 | [ALB + ASG High Availability](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/06-alb-asg-high-availability.md) | Stateless web tier resilience |
| 07 | [Lambda API + DynamoDB](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/07-lambda-api-gateway-dynamodb.md) | Serverless CRUD API |
| 08 | [NAT Gateway Patterns](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/08-nat-gateway-private-subnets.md) | Private subnet egress |
| 09 | [VPC Endpoints](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/09-vpc-endpoints.md) | Private AWS service access |
| 10 | [Peering vs TGW](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/10-vpc-peering-vs-transit-gateway.md) | Multi-VPC connectivity |
| 11 | [Route 53 Failover](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/11-route53-failover.md) | DNS-based DR |
| 12 | [SNS + SQS + Lambda](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/12-sns-sqs-lambda.md) | Fanout and buffering |
| 13 | [KMS + Secrets + Parameter Store](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/13-kms-secrets-parameter-store.md) | Secret and config management |
| 14 | [WAF + ALB + Shield](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/14-waf-alb-shield.md) | L7 protection |
| 15 | [CloudTrail + Config + GuardDuty](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/15-cloudtrail-config-guardduty.md) | Governance and detection |
| 16 | [CloudFront + S3 OAC](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/16-cloudfront-s3-oac.md) | Private static delivery |
| 17 | [ECS Fargate Basics](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/17-ecs-fargate-basics.md) | No-host containers |
| 18 | [ElastiCache Session Store](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/18-elasticache-session-store.md) | Shared low-latency state |
| 19 | [3-Tier Reference Architecture](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/19-3tier-reference-architecture.md) | End-to-end web app |
| 20 | [Event-Driven Ordering](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/20-serverless-event-driven-ordering.md) | Asynchronous workflows |
| 21 | [Backup and DR Strategy](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/21-backup-dr-strategy.md) | Recovery planning |
| 22 | [Observability](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/22-observability-cloudwatch-xray.md) | Logs, metrics, traces |
| 23 | [Cost Optimization](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/23-cost-optimization-lab.md) | Spend reduction |
| 24 | [Multi-Account Landing Zone](/D:/MASTER/PROJECTS/AWS-SAA-Custom-Labs/labs/24-multi-account-landing-zone.md) | Org-wide guardrails |

Useful links:
- [Merge-to-main troubleshooting guide](docs/merge-main-fix.md)
- [Lab writing standard](docs/lab-writing-standard.md)
- [Study plan](docs/study-plan.md)
- [Exam tips](docs/exam-tips.md)

Repository layout:
- `labs/` individual lab notes
- `docs/` supporting guides
- `assets/` diagrams and screenshots
