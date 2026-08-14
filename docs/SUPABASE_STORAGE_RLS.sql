-- =====================================================
-- SHELTER CRM · Supabase Storage RLS · property-images bucket
-- =====================================================
-- Copy ทั้งไฟล์นี้ → Supabase Dashboard → SQL Editor → New query → Paste → RUN
-- ไม่ทำลาย policy อื่น · เพิ่ม 4 policies ใหม่ · scope เฉพาะ bucket 'property-images'

-- 1. อ่านสาธารณะ (Public bucket toggle จัดให้แล้ว · policy นี้ explicit ไว้เพื่อชัดเจน)
CREATE POLICY "shelter public read property-images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'property-images');

-- 2. อัปโหลด · anon role (CRM ใช้ anon key)
CREATE POLICY "shelter anon upload property-images"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (bucket_id = 'property-images');

-- 3. แก้ไข (overwrite/upsert) · anon role
CREATE POLICY "shelter anon update property-images"
ON storage.objects FOR UPDATE
TO anon, authenticated
USING (bucket_id = 'property-images')
WITH CHECK (bucket_id = 'property-images');

-- 4. ลบ · anon role
CREATE POLICY "shelter anon delete property-images"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (bucket_id = 'property-images');

-- =====================================================
-- ตรวจสอบหลัง RUN — ควรเห็น 4 policies ใหม่
-- =====================================================
-- Storage → Buckets → property-images → Policies tab
-- ควรมี: read, upload, update, delete (4 policies) · applies to property-images

-- =====================================================
-- ROLLBACK (ถ้าอยากลบ 4 policies กลับ)
-- =====================================================
-- DROP POLICY "shelter public read property-images" ON storage.objects;
-- DROP POLICY "shelter anon upload property-images" ON storage.objects;
-- DROP POLICY "shelter anon update property-images" ON storage.objects;
-- DROP POLICY "shelter anon delete property-images" ON storage.objects;
