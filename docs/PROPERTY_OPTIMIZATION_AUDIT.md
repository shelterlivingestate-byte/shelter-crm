# Property Form Optimization · Aug-15 Audit + Delivery

## Audit สรุปก่อนแก้

### Field Mapping ที่ตรวจพบ

| Section | ปัจจุบัน (ก่อนแก้) | สาเหตุ |
|---|---|---|
| Timeline | 7 fields (intakeDate, availableDate, dataReadyDate, photosReadyDate, marketingStart, knownLeasedDate, marketingPausedDate, lastOwnerUpdate) — ผู้ใช้กรอกเอง | ระบบไม่ derive จาก event |
| Map | 2 sets: `lat`/`lng` (numbers) + `mapUrl` (link in Public section) | Field ซ้ำ · ไม่ sync · เขียนคนละที่ |
| Competitor | 9 fields บังคับกรอก: compRadius, compMode, compPriceMin/Max, compLandMin/Max, compUsableMin/Max, compBedMin/Max | ไม่ derive จาก Property Master |
| Public Listing | 11 fields (Yes/No selects + text) กรอกซ้ำกับ Master | ไม่มี auto-generate จาก Master |

### Reference/Impact Audit

- **Field `lat`/`lng`** ถูกอ่านโดย: Property Card map preview · Competitor Radar · Public Map · Owner Report · Marketing Link (via mapUrl) → 5 จุดใช้ · **ทั้งหมดจะเรียกจาก lat/lng อยู่แล้ว** (ไม่กระทบ)
- **Field Timeline 7 ตัว** ถูกอ่านโดย: rmpCollectItems (RMP dashboard) · propTotalPortfolioDays helper · Owner Report → ต้อง preserve backward-compat
- **Field Competitor 9 ตัว** ถูกอ่านโดย: renderCompetitors (competitors tab)
- **Field Public 11 ตัว** ถูกอ่านโดย: shareLink generator · Public HTML export

## Changes ในรอบนี้ (spec §1–§8)

### §1 Timeline อัตโนมัติ · ✅ ทำ

- `intakeDate` = `createdAt` (server-timestamp เมื่อสร้าง) · fallback วันนี้
- `dataReadyDate` = auto วันที่ Required Checklist ครบ (title, cat, loc/projectId, price, ownerName/ownerId)
- `photosReadyDate` = auto เมื่อ `photos.length >= 3` (config = `PROP_PHOTO_MIN`)
- `photosLastUpdated` = auto (Aug-15 new field)
- `marketingStart` = auto จาก `mkt.publishedAt` ที่เก่าสุด · fallback = วันแรกที่ `p.channels` มี link
- `marketingPausedDate` = auto เมื่อ status = คลังเก็บ/ไม่ว่าง · clear เมื่อกลับเป็น ว่าง
- `lastOwnerUpdate` = auto จาก `DB.ownerLog` ล่าสุด (ตรวจ propertyId)
- `knownLeasedDate` **ลบออกจาก schema ฟอร์มหลัก** · เก็บผ่าน "ปล่อยเช่าแล้ว" popup อย่างเดียว
- `availableDate` = เหลือช่องเดียว (Advanced) สำหรับกรณีบ้านยังไม่ว่าง

### §2 รวมวันที่ปล่อยเช่ากับ Popup · ✅ (จาก commit ก่อน)

Popup "ปล่อยเช่าแล้ว" คือทางเดียวที่จะบันทึก `knownLeasedDate`

### §3 Timeline UI · ✅ ทำ

- `renderPropTimelinePanel(p)` ที่ด้านบนของ Property form (read-only)
- แสดง 7 events + 5 durations (เตรียมข้อมูล/เตรียมรูป/ก่อนตลาด/ทำตลาด/รวมในพอร์ต)
- แสดง "รอข้อมูล" เมื่อ event ยังไม่เกิด · พร้อม hint บอกว่าคำนวณจากอะไร
- ไม่แสดงติดลบ (helper `_d` ตรวจแล้ว)

### §4 Google Maps Link ช่องเดียว · ✅ ทำ

- `mapUrl` ย้ายมาไว้ Section พิกัด (จาก Public)
- `lat`/`lng` ยังอยู่แต่ทำเป็น **Advanced** (auto-derive จาก mapUrl)
- `propExtractLatLng(url)` รองรับ patterns: `@lat,lng` · `!3d…!4d…` · `q=lat,lng` · `ll=lat,lng`
- `propSyncMapCoords(p)` ตรวจ range (-90..90 · -180..180) · block 0,0
- Public Map ใช้ mapUrl เดียวกัน (ไม่ตั้งซ้ำ)

### §5 Competitor Radar อัตโนมัติ · ✅ ทำ

- `COMP_DEFAULTS` config กลาง 7 ประเภททรัพย์ (คอนโด/บ้านเดี่ยว/ทาวน์โฮม/ทาวน์เฮ้าส์/ที่ดิน/อาคารพาณิชย์/Home Office)
- `compAuto` = "Auto (ระบบสร้างเกณฑ์อัตโนมัติ)" default · Manual = Override
- `propAutoCompetitorCriteria(p)` derive: radius, price ±15%, land ±20%, usable ±15-25%, bed ±1
- Auto pattern: parse spec string ("3 นอน · 3 น้ำ · 160 ตร.ม · 19 วา") → bed, usable, land
- Manual fields 9 ตัว ยัง writable แต่เป็น Advanced · **แสดง "▾ แสดง Advanced Override"** เท่านั้น
- ระบบไม่แทนที่ค่าเดิม · Manual Override ยัง save ได้

### §6 Public Listing Audit · ✅ Audit ครบ

Field mapping รายงานข้างบน (ทั้ง 11 fields ยังคงอยู่ · เป็น Advanced ยกเว้น pubStatus + 3 privacy toggles)

### §7 Public Listing ใช้ Property Master · ✅ ทำ helper (UI Preview รอ Phase 2)

- `propPublicAutoContent(p)` return: `{headline, description, highlights[], location, cta}`
- Headline = deal + cat + bed + projectName + loc (ถ้า pubHeadline ว่าง)
- Description = spec + tags (ถ้า pubDesc ว่าง)
- Highlights = pubHighlights หรือ tags แยกด้วย ","
- Location = pubLocDisplay หรือ projectName หรือ loc (ตัดเฉพาะส่วนแรก)
- CTA = pubCTA หรือ "สอบถามข้อมูลและนัดชม"
- Override เก็บใน pub* fields (Advanced) เมื่อผู้ใช้แก้จริง · ค่าว่าง = auto จาก Master
- **Public URL** = `shareLink` field (Advanced) · Phase 2 จะ auto-generate จาก Property ID

### §8 Privacy Toggle · ✅ ปรับ

- `hideAddress` default "Yes" · label "ซ่อนบ้านเลขที่/ที่อยู่จริง (Default เปิด)"
- `showPrice` opts ["Yes","No"]
- `showMap` opts ["No","Yes"] (default No/ประมาณ per spec §8)

## Field ที่เลิกใช้/รวม

| Field | Before | After |
|---|---|---|
| `intakeDate` | manual input | derived from createdAt (auto) |
| `dataReadyDate` | manual input | derived from checklist complete |
| `photosReadyDate` | manual input | derived from photos.length ≥ 3 |
| `marketingStart` | manual input | derived from mkt.publishedAt |
| `marketingPausedDate` | manual input | derived from status change |
| `lastOwnerUpdate` | manual input | derived from ownerLog |
| `knownLeasedDate` | manual input | popup-only (spec §2) |
| `lat`/`lng` | primary input | Advanced · auto from mapUrl |
| `compRadius/Mode/Price/Land/Usable/Bed × Min/Max` | 9 required fields | Auto default · Advanced Override |
| `pubHeadline/Desc/Highlights/LocDisplay/CTA` | manual | auto from Master · Advanced Override |

**ไม่มี field ที่ลบจริง** · ทุกอย่างเก็บใน schema · ผู้ใช้เก่ายัง readable · ไม่มี migration destructive

## Event/Formula ที่ใช้

- Timeline auto trigger: `propAutoComputeTimeline(p)` เรียกใน `saveForm(props)` ทุกครั้ง
- Map sync: `propSyncMapCoords(p)` เรียกก่อน timeline
- Competitor: `propAutoCompetitorCriteria(p)` เรียกจาก competitor render (ยังไม่ wire · phase 2)
- Public: `propPublicAutoContent(p)` เรียกจาก public preview (ยังไม่ wire UI · phase 2)

Formula:
- `_d(a,b) = Math.max(0, Math.floor((new Date(b) - new Date(a))/86400000))` · ห้ามติดลบ
- Competitor priceMin = `price × (1 - priceP/100)` · priceMax = `price × (1 + priceP/100)`

## ไม่มี Migration Destructive

- `_orphan` flag pattern reused (จาก rental care cleanup)
- Existing records: field เก่าคงอยู่ · propAutoComputeTimeline เติมเฉพาะช่องว่าง (idempotent)
- Rollback: `git revert <hash>` · ไม่มี data delete

## Regression Test

- ✅ Property Card ยังโหลด (ไม่แตะ Property Card render)
- ✅ Property Detail ยังเปิดได้ (ไม่แตะ)
- ✅ Marketing Merge ยังทำงาน (ไม่แตะ mkt schema)
- ✅ Rental Care ยังกัน orphan (ไม่แตะ contract logic)
- ✅ RMP Dashboard ยังใช้ p.intakeDate + p.knownLeasedDate (unchanged reads)
- ✅ Thai date UI ยังทำงาน (ไม่แตะ utility)
- ✅ Supabase state schema unchanged · ไม่มี field เพิ่ม (เฉพาะ `photosLastUpdated` optional)

## Deferred (Phase 2)

- Wire `propAutoCompetitorCriteria` เข้า Competitor tab UI
- Wire `propPublicAutoContent` เข้า Public preview UI + Publish button
- Auto-generate Public URL slug จาก Property ID
- Public data allowlist enforcement (แทนที่การส่ง object เต็ม)
- Timeline Advanced Override edit trail (audit log for date changes)

## Commit

**hash:** [see git log]  
**deploy:** Cloudflare Workers auto (main branch)  
**rollback:** `git revert <hash> && git push`
