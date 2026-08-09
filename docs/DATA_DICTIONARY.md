# SHELTER CRM — Data Dictionary

> เอกสารอ้างอิงแหล่งความจริงของ 25 DB keys ใน `crm_state.doc`
> อัปเดตล่าสุด: 2026-08-09 · เพิ่มโดย Phase 0
> ต้องอัปเดตทุกครั้งที่เพิ่ม/แก้ field หรือ DB key ใน `index.html`

## ภาพรวม state shape

```
localStorage["shelteros_crm_v2"] = JSON.stringify({
  DB: { ...25 keys ทุก key เป็น array... },
  kb: [],           // Knowledge base entries
  todos: [],        // Daily focus todos (Dashboard)
  needsState: []    // Discovery checklist ticks
})
```

ใน Supabase: `crm_state` table · row `id=1` · column `doc` = string ของ JSON ข้างบน · column `updated_at` = ISO timestamp

## 25 DB keys

| # | Key | บทบาท | Primary ID | Foreign IDs | Writer หลัก | Reader หลัก |
|---|---|---|---|---|---|---|
| 1 | `owners` | Owner Master | `id` (uid) | — | Owner CRM · migrateOwners | Owner CRM · Owner Report · ownerOf() |
| 2 | `props` | Property Master (ทั้ง ขาย+เช่า) | `id` (uid) | `ownerId`, `projectId` | Property form (openForm 'props') | ทุก module |
| 3 | `projects` | Projects Database | `id` (uid) | — | Projects form | Property form (projectselect) · Competitor tier |
| 4 | `leads` | Customer Master (Buyer/Tenant/Seller/Landlord รวม) | `id` (uid) | — | Lead form (openLeadForm) | Customer Hub · Appointments · Deals · Contracts (tenantId) |
| 5 | `deals` | Deal Pipeline | `id` (uid) | `customerId`(=leads.id) หรือ `custId` (legacy), `propertyId`, `prop` (fallback ข้อความ) | Deal form | Pipeline · Owner Report (คำนวณ won) · Finance |
| 6 | `contracts` | สัญญาเช่า/ขาย | `id` (uid) | `propertyId`, `tenantId`(=leads.id), `dealId` | Rental Care save · Contract form | Rent Care · Rental Commissions · Owner Report |
| 7 | `appointments` | นัดหมาย (โทร/ประชุม/นัดชม/นัดเซ็น/โอน/ส่งมอบ) | `id` (uid) | `customerId`(=leads.id), `propertyId` | Appointment form | Appointments panel · Action Center · Customer Detail |
| 8 | `ownerReports` | Owner Report drafts (generated) | `id` (uid) | `propertyId`, `ownerId`, `period` | upsertOwnerReport() (Owner Report view) | Owner Report view (list ตาม property + period) |
| 9 | `ownerLog` | Owner Activity Log | `id` (uid) | `ownerId` หรือ `propertyId` | Owner interactions (create/edit) | Owner CRM · Owner Report timeline |
| 10 | `ownerCare` | Owner care actions | `id` (uid) | `ownerId` | Owner Care UI | Rental Care · Owner CRM |
| 11 | `tenantCare` | Tenant care actions | `id` (uid) | `tenantId`(=leads.id) หรือ `contractId` | Tenant Care UI | Rental Care · Customer Detail (rental tab) |
| 12 | `care` | After-sales care (ทั่วไป) | `id` (uid) | — | Care form | After-Sales Care view |
| 13 | `rentLedger` | ค่าเช่า / บันทึกการเงินตามสัญญา | `id` (uid) | `contractId` | Rent Ledger UI | Rental Care · Finance summary |
| 14 | `rentalCommissions` | คอมมิชชั่นค่าเช่า | `id` (uid) | `contractId` | rentalCommOf() / Rental Care save | Rental commissions · Finance · Action Center |
| 15 | `rentTasks` | งานตามสัญญา (auto checklist) | `id` (uid) | `contractId`, `tag` (ใช้กัน dedup) | generateCareChecklist() · rcAddTask() | Rental Care checklist · Action Center |
| 16 | `repairs` | ประวัติซ่อม | `id` (uid) | `contractId` หรือ `propertyId` | Repairs UI | Rental Care · Owner Report |
| 17 | `inspections` | บันทึกตรวจสภาพก่อน/หลังเช่า | `id` (uid) | `contractId` | Inspection form | Rental Care · Contract detail |
| 18 | `mkt` | Marketing campaigns / channels | `id` (uid) | `propertyId` | Marketing form (openForm 'mkt') | Property Marketing view · Owner Report |
| 19 | `cons` | Digital Advisor / Consult sessions | `id` (uid) | `customerId` หรือ `propertyId` | Consult UI · renderConsult | Consult view |
| 20 | `competitors` | คู่แข่งในโซน / โครงการ | `id` (uid) | `competitorProjectId`(=projects.id), `propertyId` | Competitor form | Owner Report · Market Intel |
| 21 | `finance` | ธุรกรรมการเงินสรุป | `id` (uid) | `dealId` หรือ `propertyId` | Finance form | Finance view · Dashboard |
| 22 | `income` | รายรับ (แยกแหล่ง) | `id` (uid) | `dealId` หรือ `propertyId` | Income form | Finance summary |
| 23 | `expense` | รายจ่าย (รวม marketing cost) | `id` (uid) | `propertyId` หรือ `dealId` | Expense form | Finance summary · Owner Report (marketing cost) |
| 24 | `settings` | Config user-defined | `id` (single) | — | saveTaxSettings() etc. | ทุก module |
| 25 | `auditLog` | Change log สำหรับตรวจย้อน | `id` (uid) | field `entity`, `entityId` | auditLog() wrapper | renderAudit() ใน Backup modal |
| 26 | `ownerMergeQueue` | คิว review สำหรับ owner match (Phase 1 infra) | `id` (uid) | `propertyId`, candidate `ownerId` | (Phase 2+ populate) | (Phase 2+ UI) — ตอนนี้ยัง passive |

## นอก DBKEYS แต่อยู่ใน state root

| Key | บทบาท | Writer | Reader |
|---|---|---|---|
| `kb` | Knowledge Base entries | Knowledge form · openForm('kb') | Knowledge view · AI Playbooks |
| `todos` | Daily focus (Part 2: display removed from Dashboard; data preserved) | (form removed in Part 2) | (no visible reader; state kept for future Action Center integration) |
| `needsState` | Needs Discovery checklist tick state | Consult UI | Consult UI |

## Part 2 additions (frontend-only, no DB change)

- **Global filter state** (in-memory only, not persisted): `dashScope = {range, type, customFrom, customTo}` · default `range="month"`
- **View `#v-mindset`**: separate view for Vision + 10 principles (moved from `#v-dashboard`)
- **Module registry**: `dashboard` renamed to "Executive Dashboard" · new `mindset` module added
- **Bottom Nav** DOM (mobile only): 5 tabs (dashboard / alerts / customers / propsSale / __menu)
- Reader-only computed views on Dashboard read from: `DB.income, DB.expense, DB.deals, DB.leads, DB.props, DB.mkt, DB.owners, DB.contracts, DB.rentalCommissions`

## ตัวย่อและกฎการ normalize

- `uid()` → `"id" + Date.now().toString(36) + Math.random().toString(36)` (~15 chars, monotonic)
- `normPhone()` → E.164 (`+66xxxxxxxxx`)
- `normOwKey(name, phone)` → dedup key ของ owners
- Timestamps ทั้งหมด ISO 8601 UTC (`new Date().toISOString()`)

## Sync ระหว่างอุปกรณ์

- Local: `localStorage["shelteros_crm_v2"]` — เขียนทุกครั้งที่ `save()` ถูกเรียก · timestamp ที่ `shelter_data_ts`
- Cloud: `crm_state` row id=1 · push อัตโนมัติ 3.5 วิ หลัง save (throttle) · pull ทุก 20 วิ ถ้า `SB_POLL` เปิด
- **Phase 0 guard (`applyCloudDoc`):** ถ้า local ts > cloud ts จะ **ไม่ apply** (กัน local ที่ยังไม่ push หาย) · เก็บ snapshot local ลง backup list ก่อน apply เสมอ

## รายละเอียด field ที่พบบ่อย

**owners:** `id, name, phone (E.164), line, email, notes, createdAt, updatedAt`
**props:** `id, code, title, deal ("ขาย"|"เช่า"), price, zone, projectId, ownerId, ownerName (legacy), ownerPhone (legacy), ownerLine (legacy), marketingStart, status, notes, images[]`
**leads:** `id, n (name), ph (phone), ltype ("ซื้อ"|"เช่า"|"ขาย"|"ปล่อยเช่า"), stage, score, needs {}, source, lastContact, createdAt`
**deals:** `id, customerId (or custId legacy), propertyId, prop (text fallback — Phase 1 จะเลิก), stage (0-5), val, notes`
**contracts:** `id, propertyId, tenantId, dealId, startDate, endDate, rent, deposit, status, careActive, ownerId (derived)`
**appointments:** `id, customerId, propertyId, kind, at, place, mapUrl, owner (assignee), status, feedback, nextAction, followupDate`
**ownerReports:** `id, propertyId, ownerId, period, status, advisorAnalysis, createdAt, dataUpdatedAt`

## Field ที่ยังไม่มี — แต่คาดว่าจะเพิ่มใน Phase ถัดไป

- `props.marketingScore`, `props.priceHistory[]` (Phase 4)
- `contracts.letBy` = "us"|"owner"|"other_agent" (Phase 5)
- `rentalCommissions.vat, .wht, .vatRate, .whtRate` (Phase 5)
- ตาราง `activities` ใหม่ (Phase 3 — Activity Timeline กลาง)
- ตาราง `ownerMergeQueue` ใหม่ (Phase 1)
- `leads.journeys[]` (Phase 2 — multi-journey ต่อ 1 Customer)
- `leads.needs` ขยาย 20+ fields (Phase 2)

## หมายเหตุความสัมพันธ์

- **Owner ↔ Property:** 1:N ผ่าน `props.ownerId` · ปัจจุบัน migrateOwners() auto-link ทาง name+phone → **Phase 1 จะเลิก auto** (ทำเป็น review queue)
- **Customer ↔ Deal:** 1:N ผ่าน `deals.customerId` (มี `custId` alias เก่า)
- **Customer ↔ Appointment:** 1:N ผ่าน `appointments.customerId`
- **Property ↔ Contract:** 1:N ผ่าน `contracts.propertyId` (active มักมีอันเดียว)
- **Contract ↔ RentTask / Repair / Inspection / RentalCommission:** 1:N ผ่าน `contractId`
- **Property ↔ Marketing / Owner Report / Competitor:** ทั้งหมดผ่าน `propertyId`
