# SHELTER CRM · Project Status & Handoff

> **📌 FOR NEW AI SESSIONS:** อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง · เข้าใจสถานะทั้งหมดใน 2 นาที · อัพเดทท้ายไฟล์ทุกครั้งที่จบงาน

**Last updated:** 2026-08-20 · **Current commit:** `be4a126`
**Owner:** shelterlivingestate@gmail.com

---

## 🚨 CRITICAL RULES (ห้ามละเมิด · จำเป็นทุกครั้ง)

1. **ห้าม Reset / Re-seed / Clear / Overwrite ข้อมูลเดิม** · DATA SAFETY = Priority #1
2. **ห้ามสร้างฐานข้อมูล/Supabase project ใหม่** · ใช้ตัวเดิมเท่านั้น
3. **ห้ามใส่ `service_role key` ใน frontend** · ใช้ `anon key` + RLS เท่านั้น
4. **ห้าม login เข้า Google Cloud / n8n / Supabase account ของผู้ใช้** · ให้ผู้ใช้ทำเอง
5. **ทุก save() มี sanity check** (commit `4d0c6e2`) · อย่าปิด check นั้น
6. **Cloud = authoritative · localStorage = cache** · resolve conflict favor cloud

---

## 🏗️ Architecture (สรุปย่อ)

| Layer | Service | URL / Path |
|---|---|---|
| **Code** | GitHub | `github.com/shelterlivingestate-byte/shelter-crm` (branch `main`) |
| **Hosting** | Cloudflare Pages | Auto-deploy on `git push` · ~1 นาที |
| **Domain** | Cloudflare DNS | `crm.shelterlivingestate.tech` |
| **Database** | Supabase Postgres | Table `crm_state` (single-row JSON blob) |
| **Backup** | Supabase Postgres | Table `shelter_backups_v1` (rolling 3 daily) |
| **File Storage** | Supabase Storage | Bucket `property-images` (public) |
| **Local Cache** | Browser localStorage | Key `shelteros_crm_v2` (per-device) |
| **Sheets Sync** | n8n webhook | `n8n.shelterlivingestate.tech` → SHELTER Data |

**Structure:** Single HTML file `index.html` (~2.5 MB · 7,700+ บรรทัด · Vanilla JS · **no build step**)

**Sync flow:** REST POST → poll 20s → BroadcastChannel → `beforeunload` emergencyPush

---

## ✅ DONE (จบแล้ว · เสถียร · ไม่ต้องแตะ ยกเว้น regression)

### Property Management
- ✅ Property form optimization (Timeline auto · Map single · Competitor auto · Public auto) — `06c9754`
- ✅ Property spec split 5 fields (bed/bath/usable/land/floor) — `492c9a1`
- ✅ Property autofill จาก Project Master (loc + tags + name + highlights) — `15bae20`, `78112a9`, `82d2035`
- ✅ Property form reorder key fields · hide sale-only บน rent — `5453610`
- ✅ Owner duplicate detection · fix false positives + dismiss — `24d4445`

### Rental Care
- ✅ Rental Care cleanup · fix ค้างชำระเก๊ + eligibility gate — `efd9ee8`
- ✅ Rental Market Performance section — `8f720c8`
- ✅ Rental commission · other-channel lost = 1 month rent — `1380b37`
- ✅ Rental Care Dashboard · clean UI · no duplicate notifications — `56fd325`

### Action Center
- ✅ Split Owner vs Customer · Journey hints · Calendar · Notification — `0625685`
- ✅ Cloud-sync done/snooze (was localStorage-only causing desktop/mobile mismatch) — `7c4bedc`
- ✅ Minimal mode default · daily schedule + simple checkable todo — `b2b3122`

### Marketing
- ✅ Unified 2 templates (SALE + RENT) all platforms — `4860b77`
- ✅ Marketing template pulls full Project Master data — `82d2035`

### Appointments / LINE
- ✅ Appointment message · add "ขอบคุณค่ะ" + strip CRM URL — `9d5ae31`
- ✅ LINE preview card removal (meta referrer + OG) — `84ff2a7`
- ✅ LINE direct-open restored — `0d1f48e`
- ✅ LINE desktop flow · restore open plugin · remove blocking alert — `be4a126` **(ล่าสุด)**

### Infrastructure / Safety
- ✅ Supabase Storage migration · RLS SQL + auto-backup + per-photo verify — `4302d00`
- ✅ save() sanity check · prevent accidental data zeroing — `4d0c6e2`
- ✅ n8n · diagnoseN8N() button + URL guard — `17a5135`, `3949c85`
- ✅ Thai date UI (DD/MM/BBBB display · ISO in DB) — `a713928`
- ✅ System blueprint doc (architecture + backup layers) — `e376c65`

---

## 🚧 PENDING / WAITING ON USER

### 🔴 High priority
- ⏳ **n8n workflow publish** · user ต้อง Double-click node → เลือก credential → Publish workflow → copy Production URL → paste เข้า CRM
  - Status: workflow ยังเป็น Test mode ("Waiting for you to call the Test URL")
  - Blocker: user side · ไม่มีใครทำแทนได้ (ต้อง login n8n)

### 🟡 Medium priority
- ⏳ **README.md สำหรับ handoff โปรแกรมเมอร์ใหม่** · user เพิ่งขอ · ยังไม่เขียน
- ⏳ **PROJECT_STATUS.md maintenance** · ไฟล์นี้เอง · ต้อง update ทุกครั้งที่ปิดงาน

### 🟢 Low priority / Deferred (Phase 2)
- ⏳ Wire `propAutoCompetitorCriteria` เข้า Competitor tab UI
- ⏳ Wire `propPublicAutoContent` เข้า Public preview UI + Publish button
- ⏳ Auto-generate Public URL slug จาก Property ID
- ⏳ Public data allowlist enforcement (แทน object เต็ม)
- ⏳ Timeline Advanced Override edit trail (audit log)
- ⏳ Phase 3B · Photo upload UI ให้อัปโหลดตรงเข้า Supabase Storage (ไม่ผ่าน base64)

---

## ⚠️ KNOWN ISSUES / QUIRKS

- **LINE desktop share plugin** (`social-plugins.line.me/lineit/share`) ต้อง login LINE web ก่อน · workaround: กรอก LINE ID ลูกค้าใน CRM → เปิดแชทตรง (bypass plugin)
- **localStorage 5-10 MB limit** · รูปทรัพย์ต้อง migrate ไป Supabase Storage (มี button ใน จัดการข้อมูล)
- **PIN auth ไม่ใช่ Supabase Auth** · anon key จึงใช้ RLS แบบ open-write (ใน SUPABASE_STORAGE_RLS.sql)
- **buildN8NPayload** ต้องมี `owners` array · เคยลืมส่งไปทำให้ Sheet ว่าง
- **`_orphan` flag pattern** · ห้าม hard-delete records · mark orphan แล้วซ่อน UI แทน

---

## 💾 DATA LOSS INCIDENT LOG

- **2026-08-19T13:34:37** · Leads/Deals/Contracts = 0 ทั้ง local + cloud · เกิดขณะแก้ LINE send · root cause ไม่แน่ชัด · user recover ข้อมูลได้ · เพิ่ม `save()` sanity check ป้องกันซ้ำ (`4d0c6e2`)

---

## 📁 KEY FILES

- `index.html` — ทั้งแอป · **แก้เฉพาะที่จำเป็น** · commit ทันทีทุกการแก้
- `docs/SYSTEM_BLUEPRINT.html` — Architecture + backup layers (visual)
- `docs/PROPERTY_OPTIMIZATION_AUDIT.md` — Property form spec
- `docs/SUPABASE_STORAGE_SETUP.md` — วิธี setup + migration
- `docs/SUPABASE_STORAGE_RLS.sql` — RLS policies (copy → Supabase SQL editor → RUN)
- `docs/ADVISOR_RENTAL_CARE.md` — Advisor dashboard + Rental Care spec
- `docs/GOOGLE_DRIVE_SETUP.md` — Google Drive integration (legacy · ตอนนี้ใช้ Supabase Storage แทน)
- `docs/PROJECT_STATUS.md` — **ไฟล์นี้** · handoff / status board

---

## 🎯 QUICK-START สำหรับ AI แชทใหม่

1. **อ่านไฟล์นี้จบก่อน** — จะรู้สถานะทั้งหมด
2. **อ่าน CRITICAL RULES** — ห้ามทำอะไรที่ break rules
3. **ตรวจ commit ล่าสุด:** `git log --oneline -20` — ดูว่า work ล่าสุดทำอะไร
4. **ถามผู้ใช้ว่าจะทำอะไร** — อย่าเดา · ทำตามที่ขอ
5. **แก้เสร็จ → commit ทันที** — ใช้ format `<area> · <action> · <detail>` (ดู commit history เป็นตัวอย่าง)
6. **push → รอ Cloudflare deploy ~1 นาที** — บอก URL + วิธี test ให้ผู้ใช้
7. **จบงาน → update ไฟล์นี้:** ย้าย task จาก Pending → Done · เพิ่ม issue ใหม่ถ้าเจอ

---

## 📝 SESSION LOG (append เท่านั้น · ล่าสุดอยู่บน)

### 2026-08-20 · Session (Opus 4.7)
- ✅ Rental commission other-channel = 1 month rent (`1380b37`)
- ✅ LINE desktop-aware · remove blocking alert (`be4a126`)
- ✅ สร้าง PROJECT_STATUS.md (ไฟล์นี้)
- ⏳ n8n workflow publish · รอ user
- ⏳ README.md handoff · user ยังไม่ขอชัด

### 2026-08-19 · Session
- ✅ Save sanity check (`4d0c6e2`)
- ✅ n8n diagnose + URL guard (`17a5135`, `3949c85`)
- ✅ LINE hotfix restore direct-open (`0d1f48e`)
- ⚠️ DATA LOSS INCIDENT 13:34:37 (recovered)

### 2026-08-18 · Session
- ✅ Action Center cloud-sync (`7c4bedc`)
- ✅ Owner dedup fix (`24d4445`)
- ✅ Marketing templates unified (`4860b77`)
- ✅ System blueprint doc (`e376c65`)

### 2026-08-15 · Session
- ✅ Property form major optimization (`06c9754`)
- ✅ Thai date UI (`a713928`)
- ✅ Supabase Storage migration hardening (`4302d00`)
