# SAA-C03 Exam Tips (Practical)

## วิธีอ่านโจทย์ให้เร็วและแม่น
1. อ่าน constraint ก่อนเสมอ: compliance, latency, RTO/RPO, budget
2. ขีดเส้น keyword ที่บอกระดับ managed/serverless preference
3. แยก requirement เป็น Functional vs Non-functional

## Heuristics ตัดช้อยส์
- ถ้า requirement เน้นลด operational burden: มอง managed ก่อน
- ถ้าโจทย์พูดถึง HA ใน region: Multi-AZ
- ถ้าพูดถึง region outage: DR ข้าม region
- ถ้าพูดถึง read-heavy DB: read replicas / cache
- ถ้าพูดถึง private access ไป service AWS: VPC endpoints

## จุดพลาดยอดฮิต
- สับสนระหว่าง durability กับ availability
- ใช้ NAT แทน VPC endpoint โดยไม่จำเป็น
- ให้สิทธิ์ IAM กว้างเกิน requirement
- ลืมดูต้นทุนระยะยาวเมื่อเทียบ managed alternatives

## ก่อนส่งคำตอบ
- ตอบ requirement ครบทุกข้อหรือยัง?
- มี option ไหนถูกกว่าแต่ยังผ่าน constraint ไหม?
- มี security baseline (encryption/logging/least privilege) ครบไหม?
