# Fix Guide: Merge PR เข้า `main` ไม่ได้

เอกสารนี้ไว้แก้ปัญหาเวลาที่ PR merge เข้า `main` ไม่ได้ โดยเฉพาะกรณีที่เกิดจาก base branch, history, หรือ conflict

## อาการที่พบบ่อย

1. **There isn’t anything to compare / no common history**
2. **This branch has conflicts that must be resolved**
3. **Branch is out-of-date with the base branch**
4. **Required status checks have not passed**

## วิธีแก้ (แนะนำลำดับนี้)

### 1) ยืนยันว่า PR ชี้ไปที่ base = `main`
- ในหน้า PR กด `Edit`
- ตรวจว่า `base: main` และ `compare: <feature-branch>` ถูกต้อง

### 2) อัปเดต branch ล่าสุดจาก `main`

```bash
git fetch origin
git checkout <feature-branch>
git rebase origin/main
# หรือใช้ merge แทน
# git merge origin/main
```

ถ้ามี conflict:

```bash
# แก้ไฟล์ที่ conflict
# จากนั้น
git add .
git rebase --continue
```

### 3) push กลับไปยัง branch เดิม

```bash
git push --force-with-lease origin <feature-branch>
# ถ้าใช้ merge ไม่ต้อง force
```

### 4) ถ้าเจอกรณี history ไม่เชื่อมกัน (rare)

```bash
git pull origin main --allow-unrelated-histories
```

> ใช้เฉพาะเมื่อมั่นใจว่าเป็น repo เดียวกันแต่เกิดประวัติเริ่มต้นคนละเส้นจริง ๆ

### 5) เช็ก branch protection
- ตรวจ Required checks
- ตรวจ Required approvals
- ตรวจว่าไม่ได้ block จาก stale review

## Quick checklist ก่อนกด Merge
- [ ] base branch ถูกต้อง (`main`)
- [ ] branch ทัน `origin/main`
- [ ] ไม่มี conflict
- [ ] status checks ผ่าน
- [ ] approvals ครบตาม policy

## คำแนะนำสำหรับ repo นี้
- แนะนำใช้ **Squash and merge** เพื่อให้ `main` ประวัติสะอาด
- ถ้า commit ใหญ่ ให้แตก PR รอบถัดไปเป็นรายหมวด (`docs`, `labs 00-09`, `labs 10-24`) เพื่อ review/merge ง่ายขึ้น
