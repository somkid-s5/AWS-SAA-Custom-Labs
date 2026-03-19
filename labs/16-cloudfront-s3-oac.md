# Lab 16: CloudFront with S3 Origin Access Control

## Metadata
- Difficulty: Intermediate
- Time estimate: 20–30 minutes
- Estimated cost: Free Tier eligible
- Prerequisites: None
- Depends on: None

## Learning Objectives
หลังจากทำ Lab นี้เสร็จ ผู้เรียนจะสามารถ:
- สร้าง Private S3 Bucket และอัปโหลด Static Website ได้
- สร้าง CloudFront Distribution พร้อม Origin Access Control (OAC)
- กำหนด S3 Bucket Policy ที่อนุญาตเฉพาะ CloudFront ให้อ่านได้
- ยืนยันว่า Direct S3 Access ถูก Block แต่ CloudFront Access สำเร็จ

## Business Scenario
เว็บไซต์ Static (HTML/JS/CSS) ต้องให้บริการทั่วโลกด้วย CloudFront CDN เพื่อลด Latency แต่ต้องการให้ S3 Bucket เป็น Private ทั้งหมด โดยให้เฉพาะ CloudFront เท่านั้นที่เข้าถึง S3 ได้

หาก S3 เป็น Public ผู้ใช้สามารถ Bypass CloudFront ดาวน์โหลดโดยตรง ทำให้ไม่ได้รับประโยชน์จาก CDN Caching และ WAF

## Core Services
CloudFront, S3, Origin Access Control

## Target Architecture
```mermaid
graph LR
  User["End User\n(Global)"] -->|HTTPS Request| CF["CloudFront Distribution\n(Edge Location หลายแห่ง)"]
  CF -->|OAC: Signed Request\n(SigV4)| S3["S3 Bucket\n(Private, Block Public Access)"]
  S3 -->|Serve Object| CF
  CF -->|Cached Response| User
  DirectAccess["❌ Direct S3 URL"] -. "403 Forbidden" .-> S3
  BP["S3 Bucket Policy\n(Allow CloudFront OAC only)"] -->|Enforces| S3
```

## Environment Setup
```bash
# กำหนดค่าเหล่านี้ก่อนรันคำสั่งใดๆ ใน Lab นี้
export AWS_REGION=ap-southeast-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export PROJECT_TAG=SAA-Lab-16
export BUCKET_NAME="lab16-site-${ACCOUNT_ID}-${RANDOM}"
```

---

## Step-by-Step

### Phase 1 — สร้าง Private S3 Bucket และอัปโหลด HTML

สร้าง S3 Bucket แบบ Private ทั้งหมด (Block Public Access) และอัปโหลดหน้าเว็บ Static

#### 🖥️ วิธีทำผ่าน AWS Console (GUI)

1. ไปที่ **S3 → Create bucket**:
   - Bucket name: `lab16-site-<accountid>-<random>`
   - Region: `ap-southeast-1`
   - Block Public Access: เปิดทุก Option (**สำคัญมาก**)
2. คลิก **Create bucket**
3. เข้า Bucket → **Upload** → อัปโหลดไฟล์ `index.html` ที่มีเนื้อหา:
   ```html
   <h1>Hello from Private S3 behind CloudFront OAC!</h1>
   ```

#### ⌨️ วิธีทำผ่าน CLI

```bash
# สร้าง Private S3 Bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# อัปโหลดหน้าเว็บ
echo "<h1>Hello from Private S3 behind CloudFront OAC!</h1>" > index.html
aws s3 cp index.html s3://$BUCKET_NAME/index.html
```

**Expected output:** ไฟล์ถูกอัปโหลด แต่ถ้าพยายามเปิด S3 URL โดยตรงจะได้ `403 Forbidden`

---

### Phase 2 — สร้าง Origin Access Control และ CloudFront Distribution

สร้าง OAC Config แล้วสร้าง CloudFront Distribution ที่ใช้ S3 เป็น Origin พร้อม OAC

#### 🖥️ วิธีทำผ่าน AWS Console (GUI)

1. ไปที่ **CloudFront → Distributions → Create distribution**
2. Origin:
   - Origin domain: เลือก S3 Bucket ที่สร้าง
   - Origin access: **Origin access control settings (recommended)**
   - คลิก **Create new OAC** → ชื่อ `Lab16OAC` → **Create**
3. Default cache behavior:
   - Viewer protocol policy: **Redirect HTTP to HTTPS**
4. Default root object: `index.html`
5. คลิก **Create distribution**
6. สังเกตแบนเนอร์ **"Copy policy"** → คลิกเพื่อ Copy Bucket Policy ที่ต้องใส่กับ S3

#### ⌨️ วิธีทำผ่าน CLI

```bash
# สร้าง Origin Access Control
cat <<'EOF' > oac.json
{
  "Name": "Lab16OAC",
  "Description": "OAC for Lab 16",
  "SigningProtocol": "sigv4",
  "SigningBehavior": "always",
  "OriginType": "s3"
}
EOF
OAC_ID=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config file://oac.json \
  --query 'OriginAccessControl.Id' --output text)

# สร้าง CloudFront Distribution
cat <<EOF > dist-config.json
{
  "CallerReference": "lab16-cf-$(date +%s)",
  "Comment": "Lab 16 Distribution",
  "Enabled": true,
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "Lab16Origin",
      "DomainName": "${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com",
      "OriginAccessControlId": "${OAC_ID}",
      "S3OriginConfig": {"OriginAccessIdentity": ""}
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "Lab16Origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "MinTTL": 0,
    "ForwardedValues": {"QueryString": false, "Cookies": {"Forward": "none"}}
  }
}
EOF

CF_ID=$(aws cloudfront create-distribution \
  --distribution-config file://dist-config.json \
  --query 'Distribution.Id' --output text)
CF_DOMAIN=$(aws cloudfront get-distribution \
  --id $CF_ID --query 'Distribution.DomainName' --output text)
AWS_CF_ARN="arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${CF_ID}"
echo "CloudFront Domain: $CF_DOMAIN"
```

**Expected output:** CloudFront Distribution ID และ Domain Name — Distribution จะ Deploy ภายใน 5-10 นาที

---

### Phase 3 — กำหนด S3 Bucket Policy ให้ CloudFront OAC

กำหนด Policy ที่อนุญาตให้เฉพาะ CloudFront Service + Distribution ID ที่ระบุอ่าน Object ได้

#### 🖥️ วิธีทำผ่าน AWS Console (GUI)

1. ไปที่ **S3 → lab16-site-xxx → Permissions → Bucket policy**
2. วาง Bucket Policy ที่ Copy มาจาก CloudFront Console (ขั้นตอนก่อน)
3. คลิก **Save changes**

#### ⌨️ วิธีทำผ่าน CLI

```bash
cat <<EOF > cf-bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": {
    "Sid": "AllowCloudFrontServicePrincipalReadOnly",
    "Effect": "Allow",
    "Principal": {"Service": "cloudfront.amazonaws.com"},
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$BUCKET_NAME/*",
    "Condition": {
      "StringEquals": {"AWS:SourceArn": "$AWS_CF_ARN"}
    }
  }
}
EOF
aws s3api put-bucket-policy --bucket $BUCKET_NAME --policy file://cf-bucket-policy.json
```

**Expected output:** Bucket Policy ถูกกำหนดเรียบร้อย — เฉพาะ CloudFront Distribution นี้เท่านั้นที่อ่าน S3 ได้

---

## Failure Injection

ทดสอบว่า Direct S3 Access ถูก Block แต่ CloudFront Access สำเร็จ

```bash
# รอให้ Distribution Deploy เสร็จก่อน (~5-10 นาที)
# พยายามเข้า S3 โดยตรง — ควรได้ HTTP 403
curl -Is "https://${BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com/index.html" | grep "HTTP/"

# เข้าผ่าน CloudFront — ควรได้ HTTP 200 พร้อมเนื้อหา HTML
curl -s "https://${CF_DOMAIN}/"
```

**What to observe:**
- S3 Direct: `HTTP/1.1 403 Forbidden` — OAC ป้องกันไม่ให้ใครเข้าโดยตรง
- CloudFront: `<h1>Hello from Private S3 behind CloudFront OAC!</h1>` — สำเร็จ

**How to recover:** ไม่มีอะไรที่ต้อง Recover — นี่คือพฤติกรรมที่ถูกต้องตามหลัก Security Best Practice

---

## Decision Trade-offs

| ตัวเลือก | เหมาะกับ | Security | ค่าใช้จ่าย | ภาระงาน (Ops) |
|---|---|---|---|---|
| OAC (Origin Access Control) | S3 Origin ที่ต้องการ Private (Current Best Practice) | สูงสุด (SigV4, KMS Support) | ฟรี | ปานกลาง |
| OAI (Origin Access Identity) | Legacy Configurations (เลิกแนะนำแล้ว) | ปานกลาง (ไม่รองรับ KMS) | ฟรี | ปานกลาง |
| Public Bucket + CloudFront | Lab หรือ Public Content ที่ไม่ต้องการ Security | ต่ำ (ไม่ป้องกัน Direct Access) | ฟรีสำหรับ S3 | ต่ำ |

---

## Common Mistakes

- **Mistake:** ใช้ OAI แทน OAC กับ S3 Bucket ที่เข้ารหัสด้วย SSE-KMS
  **Why it fails:** OAI ไม่รองรับ SSE-KMS Encryption จะได้รับ Error เมื่อพยายามอ่าน Object AWS แนะนำให้ใช้ OAC แทน OAI สำหรับ Bucket ใหม่ทุกกรณี

- **Mistake:** เปิด S3 Bucket เป็น Public ทั้งที่ใช้ CloudFront แล้ว
  **Why it fails:** ผู้ใช้สามารถ Bypass CloudFront และดาวน์โหลดจาก S3 โดยตรง ทำให้ WAF ไม่ทำงาน Cache ไม่มีประโยชน์ และเสีย Egress ค่าใช้จ่าย S3 แทน CloudFront

- **Mistake:** แก้ไขไฟล์ใน S3 แต่เห็น Content เดิมบน CloudFront
  **Why it fails:** CloudFront Cache ไฟล์ไว้ตาม TTL ต้องทำ Cache Invalidation (`/index.html`) หรือใช้ Versioning ใน Filename เพื่อหลีกเลี่ยงปัญหา

- **Mistake:** ไม่กำหนด Default Root Object
  **Why it fails:** เมื่อผู้ใช้เปิด `https://example.cloudfront.net/` โดยไม่ระบุ File จะได้ `403 Forbidden` หรือ `Access Denied` แทนหน้าแรก

---

## Exam Questions

**Q1:** วิธีใดที่ AWS แนะนำเป็น Best Practice สำหรับการปกป้อง S3 Origin ของ CloudFront ไม่ให้ถูกเข้าถึงโดยตรง?
**A:** Origin Access Control (OAC)
**Rationale:** OAC เป็น Successor ของ OAI รองรับ SSE-KMS, มีความปลอดภัยสูงกว่าด้วย SigV4 Signing และ AWS แนะนำให้ใช้ OAC สำหรับ S3 Origin ทุก Deployment ใหม่

**Q2:** ต้องการให้เฉพาะ Premium Users เล่น Video ที่ Host บน CloudFront/S3 ได้ ควรใช้ Feature ใด?
**A:** CloudFront Signed URLs หรือ CloudFront Signed Cookies
**Rationale:** Signed URLs/Cookies ออก Token ชั่วคราวให้ผู้ใช้ที่ได้รับอนุญาต CloudFront จะตรวจสอบ Signature ก่อน Serve Content ทำให้ควบคุมการเข้าถึงได้ในระดับ Object

---

## Cleanup (เรียงลำดับตามนี้เท่านั้น — ห้ามข้ามขั้นตอน)

```bash
# Step 1 — Disable CloudFront Distribution ก่อน (AWS ไม่อนุญาตให้ลบโดยไม่ Disable ก่อน)
ETAG=$(aws cloudfront get-distribution --id $CF_ID --query 'ETag' --output text)
aws cloudfront get-distribution-config --id $CF_ID --query 'DistributionConfig' > dist-config-backup.json

# ปิด Distribution และรออย่างน้อย 3-5 นาที
# ใช้ Console หากไม่ต้องการเขียน Update JSON ให้ซับซ้อน
echo "ไปที่ CloudFront Console → Disable distribution $CF_ID แล้วรอให้ Status = Disabled"

# Step 2 — ลบ S3 Objects และ Bucket
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3api delete-bucket --bucket $BUCKET_NAME

# Step 3 — ลบ OAC (หลัง Distribution ถูกลบแล้ว)
OAC_ETAG=$(aws cloudfront get-origin-access-control \
  --id $OAC_ID --query 'ETag' --output text)
aws cloudfront delete-origin-access-control \
  --id $OAC_ID --if-match $OAC_ETAG || true

# Step 4 — ตรวจสอบ
aws s3 ls | grep lab16 || echo "✅ S3 Bucket ถูกลบแล้ว"
```

**Cost check:** CloudFront ไม่มีค่าบริการรายเดือนสำหรับ Distribution ที่ไม่มี Traffic ตรวจสอบ Distribution ที่ยังอยู่:
```bash
aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='Lab 16 Distribution'].{ID:Id,Status:Status}"
```
