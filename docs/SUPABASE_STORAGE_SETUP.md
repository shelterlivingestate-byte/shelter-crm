# Supabase Storage Setup (แก้ localStorage เต็ม)

**เป้าหมาย:** ย้ายรูปทรัพย์จาก base64 ใน localStorage → Supabase Storage · ประหยัด localStorage 99% · **คุณคลิกแค่ 1 ปุ่ม · ผมทำที่เหลือ**

## Step 1 · Supabase Dashboard (30 วินาที · ครั้งเดียว)

1. เข้า https://supabase.com/dashboard
2. เลือก project ที่ CRM ใช้ (ตัวที่ใส่ URL/Key ไว้ในเมนูจัดการข้อมูล)
3. เมนูซ้าย → **Storage**
4. กด **New bucket**
5. กรอก:
   - **Name:** `property-images` (สะกดตรงตัว · เล็กหมด · มีขีดกลาง)
   - **Public bucket:** ✅ **ติ๊กด้วย** (สำคัญมาก · ให้รูปเปิดจาก URL ได้)
   - Restrict file size (optional): 5 MB
   - Allowed MIME types (optional): `image/*`
6. กด **Save**

## Step 2 · CRM (10 วินาที)

1. เปิด CRM → **จัดการข้อมูล**
2. กล่องเขียว **"💚 ย้ายรูปไป Supabase Storage"**
3. กด **🚀 ย้ายรูปเก่าไป Supabase Storage**
4. Confirm → ระบบย้ายทีละรูป (progress แสดงในหน้า)
5. เสร็จ · **localStorage เบา · save ได้ทันที**

## ที่เหลือผมทำแล้ว

- ✅ Code upload photo → Supabase Storage (`uploadPhotoToSupabase`)
- ✅ Migration function (`migratePhotosToSupabase`)
- ✅ UI button ใน จัดการข้อมูล
- ✅ Progress reporting
- ✅ Incremental save (crash-safe)
- ✅ Stop-on-3-fails (misconfig detection)

## RLS Policy (ถ้าต้องการล็อกให้ authenticated เท่านั้น · Optional)

ปกติเมื่อคุณติ๊ก **Public bucket** = ทุกคนอ่านได้ · ทุกคน (พร้อม anon key) อัปโหลดได้ · เพียงพอสำหรับ CRM ส่วนตัว

ถ้าอยากล็อคเข้ม (production-grade) · เข้า Supabase → SQL Editor → run:

```sql
-- อ่านได้ทุกคน (bucket เป็น public อยู่แล้ว)
-- แต่อัปโหลดได้เฉพาะ authenticated
CREATE POLICY "auth upload only"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'property-images');

-- ลบได้เฉพาะ authenticated
CREATE POLICY "auth delete only"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'property-images');
```

**หมายเหตุ:** CRM ใช้ anon key ตอนอัปโหลด · policy `authenticated` จะบล็อก · **ถ้าจะใช้ policy นี้ ต้องเพิ่ม auth flow ใน CRM ก่อน** · ปกติปล่อย public bucket ไปก่อนก็ได้

## Rollback

- ถ้า migration ผิดพลาด · รูปที่ยังไม่ย้ายไม่กระทบ
- ถ้าอยากได้ base64 กลับ · restore จาก Export ล่าสุด
- Cloud sync ปลอดภัย · Supabase state ยังเป็น authoritative

## หลัง migration

- รูปเก็บใน bucket `property-images/{PropertyCode}/{filename}`
- Public URL: `{SUPABASE_URL}/storage/v1/object/public/property-images/{PropertyCode}/{filename}`
- CRM แสดงรูปจาก URL นี้ตรงๆ · ไม่ต้องโหลดจาก localStorage
- localStorage เก็บแค่ URL string (~120 bytes/รูป แทน 200,000 bytes/รูป · **1666x เล็กลง**)

## Phase ถัดไป (Phase 3B)

ปัจจุบัน: รูป**ใหม่** ที่อัปโหลดใน CRM ยังเป็น base64 · ต้อง run migration เป็นระยะ

Phase 3B: แก้ photo upload UI ให้อัปโหลดตรงเข้า Supabase Storage เลย · ไม่ต้อง base64 อีก · บอกทำต่อได้ทุกเมื่อ

## Cost

- **Free tier:** 1 GB storage · 2 GB bandwidth/เดือน
- **Pro ($25/mo):** 100 GB storage · 200 GB bandwidth
- **ทรัพย์ 159 หลัง × 5 ภาพ × 200KB** = **~160 MB** → free tier ยังพอ

เทียบ Google Drive: 200GB ที่คุณซื้อยัง**ใช้ได้** ถ้าอยากไปทาง Drive ทีหลัง (ผมมี code + n8n workflow เตรียมไว้แล้ว)
