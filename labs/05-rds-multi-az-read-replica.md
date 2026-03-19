# Lab 05: RDS Multi-AZ vs Read Replica under Failure

## Metadata
- Difficulty: Advanced
- Time estimate: 30–45 minutes
- Estimated cost: ~$1.00–$3.00 (Multi-AZ RDS ไม่รวมใน Free Tier)
- Prerequisites: Lab 01 (VPC with isolated subnets)
- Depends on: Lab 01

## Learning Objectives
หลังจากทำ Lab นี้เสร็จ ผู้เรียนจะสามารถ:
- อธิบายความแตกต่างระหว่าง Multi-AZ Standby และ Read Replica ได้อย่างชัดเจน
- สร้าง RDS Instance แบบ Multi-AZ และ Read Replica ด้วย CLI และ Console
- ทดสอบ Automatic Failover และสังเกตพฤติกรรม DNS Endpoint ที่ไม่เปลี่ยน
- เลือก RDS Configuration ที่เหมาะสมระหว่าง HA (High Availability) และ Read Scalability

## Business Scenario
ทีมพัฒนาร้านค้าออนไลน์ต้องการให้ระบบฐานข้อมูลทนต่อเหตุขัดข้องในช่วง Maintenance และเหตุการณ์ AZ ล่ม โดยแอปพลิเคชันต้องไม่ต้องเปลี่ยน Connection String ของฐานข้อมูล

หากไม่เปิด Multi-AZ ไว้ การล่มของ Primary DB อาจทำให้ระบบหยุดทำงานเป็นชั่วโมง ส่งผลต่อรายได้อย่างมีนัยสำคัญในช่วงเวลาที่มีการใช้งานสูง

## Core Services
RDS, Multi-AZ, Read Replica, CloudWatch

## Target Architecture
```mermaid
graph TD
  App["Application Server\n(Private Subnet)"] -->|Write + Read| Primary["RDS Primary\n(Multi-AZ)"]
  Primary -->|Synchronous Replication\n(Same Region, Different AZ)| Standby["RDS Standby\n(Auto Failover)"]
  Primary -->|Asynchronous Replication| Replica["RDS Read Replica\n(Read-only Endpoint)"]
  App -->|Read-only Queries| Replica
  Primary --> CW["CloudWatch\n(DB Metrics)"]
  Standby -.->|Failover: DNS flips to Standby| App
```

## Environment Setup
```bash
# กำหนดค่าเหล่านี้ก่อนรันคำสั่งใดๆ ใน Lab นี้
export AWS_REGION=ap-southeast-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export PROJECT_TAG=SAA-Lab-05
export DB_SUBNET_GROUP="lab05-subnets"
export DB_IDENTIFIER="lab05-db"
export SUBNET1=$(aws ec2 describe-subnets \
  --filters "Name=tag:Project,Values=SAA-Lab-01" "Name=tag:Name,Values=Isolated-Subnet" \
  --query 'Subnets[0].SubnetId' --output text)

# RDS Subnet Group ต้องการอย่างน้อย 2 AZ — สร้าง Subnet ที่ 2 ใน AZ อื่นก่อน
export SUBNET2=$(aws ec2 describe-subnets \
  --filters "Name=tag:Project,Values=SAA-Lab-01" "Name=tag:Name,Values=Isolated-Subnet-2" \
  --query 'Subnets[0].SubnetId' --output text)
```

---

## Step-by-Step

### Phase 1 — สร้าง DB Subnet Group และ Multi-AZ RDS Instance

สร้าง Subnet Group ข้าม 2 AZ จากนั้นสร้าง RDS Instance แบบ Multi-AZ ซึ่งจะมี Standby ที่ Sync ข้อมูลแบบ Synchronous อยู่ใน AZ อื่นเสมอ

#### 🖥️ วิธีทำผ่าน AWS Console (GUI)

1. ไปที่ **RDS → Subnet groups** → คลิก **Create DB subnet group**
   - Name: `lab05-subnets` → VPC: Lab01 VPC
   - เพิ่ม Subnet จาก 2 AZ ที่แตกต่างกัน → **Create**
2. ไปที่ **RDS → Databases** → คลิก **Create database**
3. เลือก **Standard create** → Engine: **PostgreSQL**
4. Template: **Dev/Test** (เพื่อลดค่าใช้จ่าย)
5. ส่วน **Availability and durability**: เลือก **Multi-AZ DB instance**
6. DB Instance class: `db.t3.micro`
7. Storage: 20 GB, Disable autoscaling
8. Master username: `admin` → password: กำหนดเอง
9. VPC: เลือก Lab01 → Subnet group: `lab05-subnets`
10. คลิก **Create database** (รอ ~10 นาที)

#### ⌨️ วิธีทำผ่าน CLI

```bash
# สร้าง DB Subnet Group (ต้องครอบ 2 AZ ขึ้นไป)
aws rds create-db-subnet-group \
  --db-subnet-group-name $DB_SUBNET_GROUP \
  --db-subnet-group-description "Lab 05 subnet group" \
  --subnet-ids $SUBNET1 $SUBNET2

# สร้าง Multi-AZ RDS Instance
aws rds create-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --allocated-storage 20 \
  --master-username admin \
  --master-user-password "SuperSecretLabPass123" \
  --db-subnet-group-name $DB_SUBNET_GROUP \
  --multi-az \
  --no-publicly-accessible

# รอได้ถึง 10 นาที
aws rds wait db-instance-available --db-instance-identifier $DB_IDENTIFIER
```

**Expected output:** Instance เปลี่ยนสถานะเป็น `available` และ `MultiAZ: true`

---

### Phase 2 — สร้าง Read Replica

สร้าง Read Replica สำหรับรองรับ Read-only Queries เช่น Dashboard หรือ Report โดยไม่รบกวน Primary

#### 🖥️ วิธีทำผ่าน AWS Console (GUI)

1. ไปที่ **RDS → Databases** → เลือก `lab05-db`
2. คลิก **Actions → Create read replica**
3. กำหนดชื่อ: `lab05-db-replica` → DB Instance class: `db.t3.micro`
4. Region: ใช้ Region เดียวกัน → คลิก **Create read replica**
5. รอจนสถานะเป็น `available`

#### ⌨️ วิธีทำผ่าน CLI

```bash
aws rds create-db-instance-read-replica \
  --db-instance-identifier $DB_IDENTIFIER-replica \
  --source-db-instance-identifier $DB_IDENTIFIER

# รอให้ Replica พร้อม
aws rds wait db-instance-available --db-instance-identifier $DB_IDENTIFIER-replica
```

**Expected output:** `lab05-db-replica` ปรากฏในรายการ Databases สถานะ Replica Lag เริ่มต้นจะเป็นวินาทีหรือต่ำกว่า

---

### Phase 3 — ตรวจสอบการกำหนดค่า Multi-AZ

ตรวจสอบว่า RDS Instance กำหนดค่า Multi-AZ ถูกต้องและ Endpoint ยังคงเป็น DNS Name เดิม

#### 🖥️ วิธีทำผ่าน AWS Console (GUI)

1. ไปที่ **RDS → Databases** → เลือก `lab05-db`
2. แท็บ **Configuration** → ตรวจสอบ:
   - Multi-AZ: **Yes**
   - Secondary AZ: ระบุ AZ ของ Standby
3. สังเกต **Endpoint** — เป็น DNS Name ที่จะยังคงเดิมหลัง Failover

#### ⌨️ วิธีทำผ่าน CLI

```bash
aws rds describe-db-instances \
  --db-instance-identifier $DB_IDENTIFIER \
  --query 'DBInstances[0].{MultiAZ:MultiAZ, Endpoint:Endpoint.Address, SecondaryAZ:SecondaryAvailabilityZone}' \
  --output table
```

**Expected output:** `MultiAZ: True`, Endpoint แสดง DNS Name และ `SecondaryAvailabilityZone` บอก AZ ของ Standby

---

## Failure Injection

บังคับ Failover เพื่อสังเกตว่า DNS Endpoint ยังคงเดิม แต่ Traffic ถูกเปลี่ยนเส้นทางไปยัง Standby อัตโนมัติ

```bash
aws rds reboot-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --force-failover
```

**What to observe:** Instance เข้าสู่สถานะ `modifying` และ `rebooting` ใช้เวลาประมาณ 60–120 วินาที จากนั้น `SecondaryAvailabilityZone` (เดิม) จะกลายเป็น Primary ใหม่ **Endpoint DNS ไม่เปลี่ยน** — แอปพลิเคชันที่ Reconnect ได้จะกลับมาทำงานโดยไม่ต้องแก้ Configuration ใดๆ

**How to recover:** ระบบ Self-healing อัตโนมัติ — ไม่ต้องดำเนินการใดๆ เพิ่มเติม

---

## Decision Trade-offs

| ตัวเลือก | เหมาะกับ | RTO | ค่าใช้จ่าย | ภาระงาน (Ops) |
|---|---|---|---|---|
| Multi-AZ | High Availability / ทนต่อ AZ failure | 60–120 วินาที (อัตโนมัติ) | 2x ราคา Single AZ | ต่ำ (DNS Failover อัตโนมัติ) |
| Read Replica | Read Scalability / Analytics Offload | Manual Promote (RTO สูง) | + ราคา Instance เพิ่ม | ปานกลาง (มี Replica Lag) |
| Aurora | HA + Read Scale พร้อมกัน | < 30 วินาที | สูงกว่า RDS | ต่ำมาก (Managed) |

---

## Common Mistakes

- **Mistake:** ใช้ Read Replica แทน Multi-AZ เพื่อวัตถุประสงค์ด้าน High Availability
  **Why it fails:** Failover ของ Read Replica เป็น Manual Process — ต้องทำ Promote เอง และต้องแก้ Connection String ในแอปพลิเคชัน ไม่เหมือน Multi-AZ ที่ DNS เปลี่ยนโดยอัตโนมัติ

- **Mistake:** วาง DB Subnet Group ใน AZ เดียว
  **Why it fails:** RDS Subnet Group บังคับให้มีอย่างน้อย 2 AZ หากวางใน AZ เดียวจะสร้าง Multi-AZ Instance ไม่ได้ และไม่มีประโยชน์ด้าน HA

- **Mistake:** คิดว่าการมี Snapshot สำรองข้อมูลเพียงพอแทน Multi-AZ
  **Why it fails:** การ Restore จาก Snapshot ใช้เวลาหลายชั่วโมง (RTO สูง) และข้อมูลตั้งแต่ Snapshot ล่าสุดจนถึงเวลาที่เกิดเหตุจะสูญหาย (RPO > 0) ต่างจาก Multi-AZ ที่ Standby Sync แบบ Synchronous

- **Mistake:** ส่ง Write Queries ไปยัง Read Replica
  **Why it fails:** Read Replica รับเฉพาะ Read-only connections เท่านั้น คำสั่ง INSERT/UPDATE/DELETE จะได้รับ Error ทันที

- **Mistake:** สับสนระหว่าง Multi-AZ (Regional HA) กับ Cross-Region Read Replica
  **Why it fails:** Multi-AZ ป้องกัน AZ failure ภายใน Region เดียว Cross-Region Replica ใช้สำหรับ Disaster Recovery หรือลด Read Latency ในภูมิภาคอื่น

---

## Exam Questions

**Q1:** กลไกใดใน RDS ที่รองรับการ Failover อัตโนมัติโดยที่แอปพลิเคชันไม่ต้องเปลี่ยน Connection String?
**A:** RDS Multi-AZ
**Rationale:** Multi-AZ ใช้ DNS CNAME ที่เดิมตลอด เมื่อเกิด Failover AWS จะเปลี่ยน DNS CNAME ให้ชี้ไปยัง Standby อัตโนมัติภายใน 60–120 วินาที แอปพลิเคชันที่ Reconnect ได้จะกลับมาทำงานโดยไม่ต้องแก้ Configuration

**Q2:** Dashboard Analytics กำลัง Query ข้อมูลหนักมากจนทำให้ CPU ของ RDS Primary พุ่งสูงและส่งผลกระทบต่อแอปพลิเคชันหลัก จะแก้ปัญหาอย่างไร?
**A:** สร้าง RDS Read Replica และให้ Dashboard ใช้ Endpoint ของ Replica แทน
**Rationale:** Read Replica รองรับการขยาย Read Capacity ออก (Scale Out) โดยดึง Read Traffic ออกจาก Primary ลดภาระให้แก่แอปพลิเคชันหลัก

---

## Cleanup (เรียงลำดับตามนี้เท่านั้น — ห้ามข้ามขั้นตอน)

```bash
# Step 1 — ลบ Read Replica ก่อน
aws rds delete-db-instance \
  --db-instance-identifier $DB_IDENTIFIER-replica \
  --skip-final-snapshot
aws rds wait db-instance-deleted --db-instance-identifier $DB_IDENTIFIER-replica

# Step 2 — ลบ Primary Instance
aws rds delete-db-instance \
  --db-instance-identifier $DB_IDENTIFIER \
  --skip-final-snapshot
aws rds wait db-instance-deleted --db-instance-identifier $DB_IDENTIFIER

# Step 3 — ลบ DB Subnet Group
aws rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP

# Step 4 — ตรวจสอบว่าลบเรียบร้อยแล้ว
aws rds describe-db-instances \
  --query 'DBInstances[?contains(DBInstanceIdentifier,`lab05`)].DBInstanceIdentifier' \
  --output table || echo "✅ ไม่มี DB Instance ที่เกี่ยวกับ Lab 05 เหลืออยู่"
```

**Cost check:** RDS Multi-AZ มีค่าใช้จ่ายต่อชั่วโมง ตรวจสอบให้แน่ใจว่าไม่มี Instance ที่ค้างอยู่:
```bash
aws rds describe-db-instances \
  --query 'DBInstances[?contains(DBInstanceIdentifier,`lab05`)].{ID:DBInstanceIdentifier,Status:DBInstanceStatus}' \
  --output table
```
