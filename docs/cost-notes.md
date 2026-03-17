# Cost Optimization Notes (Hands-on Lens)

## Compute
- ใช้ rightsizing กับ EC2/ECS task size ตาม utilization จริง
- พิจารณา Savings Plans สำหรับ workload ต่อเนื่อง
- ใช้ autoscaling + scale-to-zero ใน workload ที่รองรับ

## Storage
- S3 lifecycle: Standard -> Intelligent-Tiering -> Glacier
- ลบ snapshot/volume orphan ตามรอบ
- เลือก EBS type ให้ตรง IOPS/throughput requirement

## Data & Network
- ลด cross-AZ / cross-region data transfer ที่ไม่จำเป็น
- ใช้ VPC endpoint แทน NAT egress เมื่อเหมาะสม
- ปรับ CloudFront cache policy ลด origin fetch

## Governance
- ตั้ง AWS Budgets + cost anomaly detection
- บังคับ tagging เพื่อ chargeback/showback
- review รายสัปดาห์: top cost drivers + action item
