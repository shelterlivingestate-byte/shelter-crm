# Marketing ↔ Finance · Single Source of Truth

**Round:** MASTER-2 (post-Marketing-Merge follow-up)

## Audit ก่อนแก้ · สรุปสถานะระบบเดิม

| หน่วยข้อมูล | Store เดิม | Owner (เจ้าของต้นทาง) |
|---|---|---|
| Channel enum (15 platforms) | `CHANNELS` const | ✅ Marketing Merge |
| Per-property URL map | `p.channels{key:url}` | ✅ Property Master |
| Marketing record (ประกาศ + ผล) | `DB.mkt[]` | ✅ Marketing Engine |
| **Marketing expense** | `DB.expense[]` | ✅ Finance (SSOT อยู่แล้ว) |
| Expense ↔ Campaign link | `expense.mktId` (soft) | ✅ DM-5 |
| Expense ↔ Property link | `expense.propertyId` | ✅ existing |
| Deal Commission | `DB.finance[] + income[]` | ✅ Finance |
| Rental Commission | `DB.rentalCommissions[]` | ✅ existing |
| Lead source | `DB.leads.src` (SRC const) | ✅ existing (แต่เดิม 7 ตัว) |
| Property FK | `p.id` | ✅ |
| Customer FK | `l.id` (leads) | ✅ |
| Deal FK | `d.id` | ✅ |
| Contract FK | `c.id` | ✅ |

**สรุป Audit:** SSOT infrastructure **มีอยู่แล้ว** จาก Marketing Merge — ไม่ต้องสร้างระบบใหม่ · เหลือแค่ปรับ UI ให้ผู้ใช้กรอกซ้ำน้อยลง

**จุดที่ผู้ใช้ต้องกรอกซ้ำ (ก่อนแก้):**

1. Marketing form มีช่องเงิน (`cost, boostCost, consultFee, referralFee, otherCost`) ซ้ำกับ Expense
2. Marketing form ยังมี `date` ซ้ำ `publishedAt`
3. SRC (แหล่งที่มา) มีแค่ 7 ตัว · ไม่ครบตาม spec §5 (ต้อง 15 ตัว)
4. LivingInsider credit rules 50/10 ยัง hardcode ไม่ได้ (ยังไม่มีเลย)

## Changes ในรอบนี้

### Part 1 · SCHEMA.mkt สั้นลง (spec §3, §4)

- **Title:** `"การตลาด · ช่องทาง & ค่าใช้จ่าย"` → `"เพิ่มช่องทางการลงประกาศ"`
- **Required 4:** Property + Platform + วันที่เริ่มลง + สถานะประกาศ
- **Optional:** URL + Views + Inquiries + Qualified Leads + Clicks + Saves + endedAt + name + note
- **ลบออกจาก form:** cost, boostCost, consultFee, referralFee, otherCost, date, lastUpdatedAt (auto), reach (รวมกับ views)

**Backward-compat:** ค่าเก่าใน `DB.mkt` records ยัง render ได้ · saveForm ใช้ `Object.assign(list[index],obj)` — เมื่อลบ field ออกจาก schema, obj จะไม่มี key นั้น → ค่าเดิมคงอยู่

### Part 2 · Status enum ใหม่ (spec §3)

`opts:["กำลังลงประกาศ","พักประกาศ","หมดอายุ","ปิดประกาศ","ขายแล้ว/ปล่อยเช่าแล้ว"]`

Records เก่าที่ status = "Live/Active/Paused/Expired/Removed/Draft/กำลังรัน/หยุดชั่วคราว/จบแล้ว" ยังแสดงได้ (select field ไม่ enforce enum ตอน render)

### Part 3 · SRC (Lead source) ครบ 15 ตัว (spec §5)

เดิม: `["PropertyHub","Facebook","DDproperty","Living Insider","Line OA","Referral","อื่นๆ"]`

ใหม่: `["LivingInsider","PropertyHub","DDproperty","DotProperty","Hipflat","Thailand Property","Facebook","Instagram","Website","LINE","ลูกค้าแนะนำ","Owner แนะนำ","Agent แนะนำ","ป้ายหน้าทรัพย์","อื่น ๆ"]`

Records เก่าที่ src = "Living Insider" (มีเว้น) ยังแสดงได้ · ผู้ใช้แก้ทีหลังได้เอง

### Part 4 · LivingInsider credit config (spec §9)

- `settings.liListingCredit = 50` (default · แก้ได้ในอนาคต)
- `settings.liBoostCredit = 10` (default · แก้ได้ในอนาคต)
- Helper: `liCreditsUsed(listings, boosts, rateListing?, rateBoost?)` — rate parameter ใช้ค่า ณ เวลานั้น (frozen)
- ประวัติการใช้เครดิตต้องเก็บ rate ที่ใช้ในเวลานั้น (ผู้ใช้เก็บใน record ตัวเอง — Phase 2 UI ค่อยทำ input form)

### Part 5 · Helper `mktDisplayName(m)` (spec §3)

`Property Code + Property Title + Platform` — ใช้เป็นชื่อแสดงผลอัตโนมัติเมื่อผู้ใช้ไม่กรอก name

### Part 6 · Duplicate detection (spec §10)

- **Marketing:** ถ้า property + platform + status Active ตรงกับ record เดิม → confirm() ก่อนบันทึก
- **Expense:** ถ้า platform + amount + date + category ตรงกัน → confirm() ก่อนบันทึก

## สิ่งที่ NOT ทำในรอบนี้ · ต้องรอบถัดไป

- **UI สำหรับ LivingInsider credit** (input จำนวนครั้ง + แสดงยอดคงเหลือ) — spec §9 พูดถึงหน้า input · Phase 2
- **Auto-link Lead → Marketing Record** (เมื่อ src=platform ตรงกับ mkt.ch + tracking marketingRecordId) — spec §5 · ต้องแก้ Lead form + save logic · Phase 2
- **Marketing Dashboard SSOT recompute** (Cost per Lead จาก Source ที่ยืนยันแล้ว) — spec §11 · Phase 2
- **Cost per Property เฉลี่ย** ในหน้า Marketing Dashboard — spec §12 · Phase 2

## Data safety

- **ไม่ลบข้อมูลย้อนหลัง:** ลบ field จาก schema เท่านั้น · ข้อมูลใน records เก่าคงอยู่ (Object.assign merge)
- **ไม่ renumber/reset:** ไม่แตะ property code, customer id, deal id, expense id
- **ไม่สร้างฐานข้อมูลซ้ำ:** ใช้ store เดิม (`DB.mkt`, `DB.expense`, `DB.leads.src`) ต่อ
- **ไม่ migrate ค่าเก่า:** legacy financial values ใน `DB.mkt` เก่าคงอยู่ · จะ mapping เข้า `DB.expense` ต้องรอ user review รายกรณี
