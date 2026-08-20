# SHELTER CRM · Project Status & Handoff

> **📌 FOR NEW AI SESSIONS:** อ่านไฟล์นี้ก่อนเริ่มงานทุกครั้ง · เข้าใจสถานะทั้งหมดใน 3 นาที · อัพเดทท้ายไฟล์ทุกครั้งที่จบงาน

**Last updated:** 2026-08-20 · **Current commit:** `f1694af`
**Owner:** shelterlivingestate@gmail.com

---

## 🚨 CRITICAL RULES (ห้ามละเมิด · จำเป็นทุกครั้ง)

1. **ห้าม Reset / Re-seed / Clear / Overwrite ข้อมูลเดิม** · DATA SAFETY = Priority #1
2. **ห้ามสร้างฐานข้อมูล/project ใหม่แทนผู้ใช้** · โดยเฉพาะ **Neon** — Neon MCP เลือก Singapore region ไม่ได้ · ผู้ใช้ต้องสร้างเอง
3. **ห้ามใส่ secret / API token / DB password ใน frontend** · ใช้ Cloudflare Worker เป็น proxy เท่านั้น
4. **ห้าม login เข้า account ของผู้ใช้** (Google Cloud / n8n / Neon / Cloudflare / Supabase) · ให้ผู้ใช้ทำเอง
5. **ทุก save() มี sanity check** (commit `4d0c6e2`) · อย่าปิด check นั้น
6. **Cloud = authoritative · localStorage = cache** · resolve conflict favor cloud
7. **ทุก feature ใหม่ต้องคำนึงถึง RBAC** · ห้ามสมมติว่ามี user เดียว (ดู "RBAC Upgrade Plan" ด้านล่าง)

---

## 🏗️ Architecture (สรุปย่อ · Stack ปัจจุบัน)

| Layer | Service | URL / Path | Status |
|---|---|---|---|
| **Code** | GitHub | `github.com/shelterlivingestate-byte/shelter-crm` (branch `main`) | ✅ Active |
| **Hosting** | Cloudflare Pages via **Wrangler CLI** | `wrangler pages deploy .` | 🚧 Migrating from GitHub auto-deploy |
| **Domain** | Cloudflare DNS | `crm.shelterlivingestate.tech` | ✅ Active |
| **Database** | **Neon Postgres (Singapore)** | ⏳ ยังไม่สร้าง (user ต้องสร้างเอง) | ⏳ Migrating from Supabase |
| **File Storage** | **Cloudflare R2** | Bucket `shelter-property-images` + Worker upload proxy | ⏳ Migrating from Supabase Storage |
| **Local Cache** | Browser localStorage | Key `shelteros_crm_v2` (per-device) | ✅ Active |
| **Sheets Sync** | n8n webhook | `n8n.shelterlivingestate.tech` → SHELTER Data | 🚧 Wait for user to publish workflow |
| **Legacy** | Supabase (Postgres + Storage) | ยังเก็บข้อมูลอยู่ · จะ migrate ออก | 🗄️ Archive after Neon/R2 verified |

**Structure:** Single HTML file `index.html` (~2.5 MB · 7,700+ บรรทัด · Vanilla JS · **no build step**)

**Sync flow:** REST POST → poll 20s → BroadcastChannel → `beforeunload` emergencyPush

---

## 🛠️ MCP + CLI Toolchain (AI Automation Layer)

**เป้าหมาย:** ให้ AI ทำ setup งานต่างๆ แทนผู้ใช้ให้ได้มากที่สุด · ลด manual clicking

### Required CLIs (ต้องติดตั้งเครื่องผู้ใช้)

| CLI | Command | ทำอะไรได้ | Auth |
|---|---|---|---|
| **Node.js** | Installer จาก nodejs.org | Prerequisite ของ npm/wrangler/neonctl | — |
| **Wrangler** | `npm install -g wrangler` | Cloudflare Pages/Workers/R2 deploy · tail logs · env vars | `wrangler login` |
| **neonctl** | `npm install -g neonctl` | Neon Postgres query, branch, migration | `neonctl auth` |
| **gh** | `winget install GitHub.cli` | GitHub PR/issue/release · CI status | `gh auth login` |

### Required MCP Servers (ติดตั้งใน Claude)

| MCP | Install Command | ทำอะไรได้ | ข้อจำกัด |
|---|---|---|---|
| **Cloudflare** | `claude mcp add cloudflare npx -y @cloudflare/mcp-server-cloudflare` | R2 bucket, Workers, Pages, DNS, KV, D1 · env vars, secrets | — |
| **Neon** | `claude mcp add neon npx -y @neondatabase/mcp-server-neon` | Query DB, migrations, branches, schema | ⚠️ **create project ไม่ได้** (region) |
| **GitHub** | `claude mcp add github npx -y @modelcontextprotocol/server-github` | PRs, issues, releases, CI | ต้อง PAT (Personal Access Token) |

### What AI Can Automate After Setup

**Cloudflare (MCP + Wrangler):**
- สร้าง R2 bucket · public access · custom domain
- สร้าง Worker · set env vars · bind R2
- Deploy Pages · rollback · tail logs
- Set DNS records · verify domain

**Neon (MCP + neonctl):**
- Query DB · debug data
- Create/modify tables + indexes
- Manage branches (dev/staging/prod)
- Run migrations · verify schema
- View slow queries · optimize

**GitHub (MCP + gh):**
- Create PR · review · merge
- Comment on issues · create issues from TODOs
- View CI status · retry failed jobs
- Create releases + tags

### Time Savings Example

| งาน | Manual | ด้วย MCP+CLI |
|---|---|---|
| Setup R2 bucket + Worker | 20 นาที | 30 วิ |
| Deploy CRM update | 1-2 นาที (git push + build) | 5-10 วิ (`wrangler pages deploy`) |
| Query DB debug | 5 นาที (เปิด dashboard) | 10 วิ (AI ตอบใน chat) |
| Create GitHub PR | 5 นาที (browser fill form) | 10 วิ (`gh pr create`) |

### Setup Status

- ⏳ Node.js — user ต้องติดตั้ง
- ⏳ Wrangler CLI — user ต้อง `npm install -g wrangler`
- ⏳ neonctl CLI — user ต้อง `npm install -g neonctl`
- ⏳ gh CLI — user ต้อง `winget install GitHub.cli`
- ⏳ Cloudflare MCP — user ต้อง `claude mcp add cloudflare ...`
- ⏳ Neon MCP — user ต้อง `claude mcp add neon ...`
- ⏳ GitHub MCP — user ต้อง `claude mcp add github ...` + สร้าง PAT

### Security Notes

- MCP servers อ่าน credentials จาก CLI (ทั้ง `wrangler login`, `neonctl auth`, `gh auth`)
- ห้าม commit tokens ลง git · เก็บใน `~/.claude/config.json` (locked)
- Rotate PAT ทุก 90 วัน
- AI จะขอ permission ทุก tool call · auto-approve เฉพาะ read-only ได้ (ตั้งใน `~/.claude/settings.json`)

---

## 💡 Stack Decision Rationale (2026-08-20)

**เปลี่ยนจาก Supabase → Neon + R2 · ทำไม:**
- **Cost:** Startup phase · Supabase paid tier แพงเกินไป · Neon free tier (0.5 GB) + R2 free tier (10 GB) เพียงพอ
- **อาจกลับมา Supabase ทีหลัง** เมื่อบริษัทโตขึ้น ("มั้ง" — ยังไม่แน่)
- **Neon:** Postgres compatible · migrate schema จาก Supabase ได้
- **R2:** S3-compatible · **ไม่มี egress fee** · ประหยัดกว่า S3/Supabase Storage
- **Wrangler CLI:** Deploy เร็วมาก (5-10 วิ) · ไม่ต้องรอ GitHub build

---

## 👥 RBAC Upgrade Plan (สำคัญมาก · ต้องทำก่อนจ้างพนักงาน)

**สถานะ:** ⏳ **Not started** · ระบบปัจจุบัน = PIN auth เดียว · ทุกคนที่รู้ PIN เห็นทุกอย่าง

**เป้าหมาย:** เมื่อจ้างพนักงาน · แต่ละคนเห็น/ทำได้เฉพาะที่จำเป็น · ห้ามรั่วข้อมูล commission/owner contact ให้ junior role

### 🎭 Proposed Roles (6 roles)

| Role | คำอธิบาย | Access Level |
|---|---|---|
| **Owner** (คุณ) | เจ้าของบริษัท · Full access + user management | 🔓 ทุกอย่าง |
| **Manager** | ผู้จัดการ · Approve deals + ดูการเงินทั้งหมด | 🔓 เกือบทุกอย่าง (ห้าม delete user) |
| **Sales** | เซลล์ · ดูแลลูกค้าตัวเอง + ดูทรัพย์ทั้งหมด | 👀 Own leads/deals only · no commission of others |
| **Marketing** | การตลาด · จัดการ content + ทรัพย์ | ✏️ Properties + templates · ❌ ห้ามเห็น financial |
| **Accountant** | บัญชี · Commission + contract + payment | 💰 Financial data · ❌ ห้ามแก้ property |
| **Viewer** | Report-only (partner/investor) | 👁️ Read-only reports · no PII |

### 🗺️ Function-by-Function Upgrade Map

| Feature Area | ปัจจุบัน (ก่อน RBAC) | หลัง RBAC |
|---|---|---|
| **Login / PIN** | PIN เดียว · localStorage | Email + PIN per user · DB.users[] · roles from DB |
| **Leads / Customers** | ทุกคนเห็นทุก lead | Sales เห็นเฉพาะ `ownerUserId === me` · Manager+ เห็นทั้งหมด |
| **Deals / Contracts** | ทุกคนเห็น + แก้ได้ | Sales own only · Accountant view all · Owner/Manager edit |
| **Properties** | ทุกคน CRUD | Marketing/Manager CRUD · Sales view only · Viewer view only |
| **Owner data (phone/LINE)** | เปิดเผยหมด | Sales+ เห็น · Marketing/Viewer ปิด (privacy) |
| **Commission (RMP)** | ทุกคนเห็นตัวเลข | Own commission (Sales) · All (Manager/Accountant/Owner) · Hidden (Marketing/Viewer) |
| **Rental Care** | เปิดหมด | Accountant + Owner + Manager |
| **Action Center** | ทุกคน · shared todo | Per-user todo · Owner เห็น team overview |
| **Marketing Templates** | เปิดหมด | Marketing + Manager + Owner |
| **Advisor Dashboard** | Owner-view (จริงๆ) | Owner only · hide จาก role อื่น |
| **จัดการข้อมูล (Settings)** | เปิดหมด | Owner only · Manager (subset · ไม่มี DB config) |
| **User Management** | ไม่มี | Owner only (new UI) |
| **Audit Log** | ไม่มี | Auto-log ทุก write · Owner/Manager view |

### 🏗️ Implementation Phases (Recommended Order)

**Phase 1 · Foundation (must ship first)**
1. Add `DB.users[]` schema: `{id, email, name, role, pinHash, active, createdAt}`
2. Add `DB.rolePermissions{}` config: role → allowed actions map
3. Migrate current PIN → user record (Owner role)
4. New login screen: email dropdown + PIN
5. Global `currentUser` object · loaded on login

**Phase 2 · UI Guards (hide what shouldn't be seen)**
6. Menu items: show/hide based on `can(user, "menu:advisor")`
7. Field-level hides: commission column, owner phone, etc
8. Button-level hides: Delete/Edit buttons hidden for read-only roles

**Phase 3 · Action Guards (server-side / sync-side check)**
9. Every mutation function: `if(!can(user, action)) return alert("ไม่มีสิทธิ์")`
10. Sync layer: reject writes if user lacks permission (defense in depth)
11. Audit log: `logAudit(userId, action, targetType, targetId, delta)`

**Phase 4 · User Management UI**
12. Owner menu: "จัดการผู้ใช้" → add/edit/deactivate users
13. Role assignment · PIN reset · view audit log

**Phase 5 · Advanced (later)**
14. Fine-grained: assign lead to specific sales
15. Team hierarchies: manager sees own team only
16. Territory-based access (if expand geographic)
17. Field-level encryption for sensitive PII (national ID, bank account)

### 🔑 Design Principles

- **UI hide + backend check** · ห้าม hide ใน CSS อย่างเดียว · payload ต้องกรองออกด้วย
- **Fail closed** · unknown role → deny · unknown action → deny
- **Audit everything** · เขียน = log ทุกครั้ง (ดู who did what when)
- **RBAC in Neon** · เก็บ role logic ใน DB · ไม่ hardcode ใน frontend
- **Backward compat** · legacy records ไม่มี `ownerUserId` → default to Owner (คุณ)

### 📊 Effort Estimate

- **Phase 1-2:** 2-3 sessions · Foundation + UI guards
- **Phase 3-4:** 2-3 sessions · Action guards + User UI
- **Phase 5:** ไม่มี timeline · ทำเมื่อจำเป็น

**Total ~1-2 สัปดาห์ทำงาน** (ต้อง test regression ทุก feature)

---

## ✅ DONE (จบแล้ว · เสถียร · ไม่ต้องแตะ ยกเว้น regression)

### Property Management
- ✅ Property form optimization (Timeline auto · Map single · Competitor auto · Public auto) — `06c9754`
- ✅ Property spec split 5 fields (bed/bath/usable/land/floor) — `492c9a1`
- ✅ Property autofill จาก Project Master — `15bae20`, `78112a9`, `82d2035`
- ✅ Property form reorder + hide sale-only บน rent — `5453610`
- ✅ Owner duplicate detection fix — `24d4445`

### Rental Care
- ✅ Rental Care cleanup + eligibility gate — `efd9ee8`
- ✅ Rental Market Performance section — `8f720c8`
- ✅ Rental commission · other-channel lost = 1 month rent — `1380b37`
- ✅ Rental Care Dashboard clean — `56fd325`

### Action Center
- ✅ Split Owner vs Customer · Journey hints — `0625685`
- ✅ Cloud-sync done/snooze — `7c4bedc`
- ✅ Minimal mode default — `b2b3122`

### Marketing
- ✅ Unified 2 templates (SALE + RENT) — `4860b77`
- ✅ Marketing template pulls Project Master — `82d2035`

### Appointments / LINE
- ✅ Appointment message · add ขอบคุณค่ะ + strip CRM URL — `9d5ae31`
- ✅ LINE preview card removal — `84ff2a7`
- ✅ LINE direct-open restored — `0d1f48e`
- ✅ LINE desktop flow · remove blocking alert — `be4a126`

### Infrastructure / Safety
- ✅ Supabase Storage migration + RLS — `4302d00`
- ✅ save() sanity check — `4d0c6e2`
- ✅ n8n diagnostic + URL guard — `17a5135`, `3949c85`
- ✅ Thai date UI — `a713928`
- ✅ System blueprint doc — `e376c65`
- ✅ PROJECT_STATUS.md handoff doc — `2c53fd2`

---

## 🚧 PENDING / IN-PROGRESS

### 🔴 Critical (do next)
- ⏳ **MCP + CLI toolchain install** · Node.js + Wrangler + neonctl + gh + 3 MCP servers · ดู "MCP + CLI Toolchain" section
- ⏳ **Wrangler deploy first test** · หลัง install · `wrangler pages deploy . --project-name=shelter-crm`
- ⏳ **Cloudflare R2 setup** · หลัง Cloudflare MCP ทำงาน · AI สร้าง bucket + Worker ให้ได้ · migrate `uploadPhotoToSupabase()` → `uploadPhotoToR2()`
- ⏳ **Neon DB setup** · User สร้าง project (Singapore region) เอง → paste connection string → AI ใช้ Neon MCP migrate schema
  - **⚠️ Reminder:** Neon MCP สร้าง project ไม่ได้ (region constraint)

### 🟡 High priority
- ⏳ **RBAC implementation Phase 1** · Foundation (users + roles + permissions) — see plan above
- ⏳ **n8n workflow publish** · user ต้อง Publish workflow → copy Production URL → paste เข้า CRM

### 🟢 Medium priority
- ⏳ **README.md** สำหรับ handoff โปรแกรมเมอร์ใหม่ · summarize + deploy guide
- ⏳ **PROJECT_STATUS.md maintenance** · update ทุก session

### 🔵 Deferred (Phase 2)
- ⏳ Wire `propAutoCompetitorCriteria` → Competitor tab UI
- ⏳ Wire `propPublicAutoContent` → Public preview UI
- ⏳ Auto-generate Public URL slug
- ⏳ Public data allowlist enforcement
- ⏳ Timeline Advanced Override audit log
- ⏳ Phase 3B · Photo upload UI direct-to-R2 (no base64)

---

## ⚠️ KNOWN ISSUES / QUIRKS

- **LINE desktop share plugin** ต้อง login LINE web ก่อน · workaround: กรอก LINE ID ใน CRM → เปิดแชทตรง
- **localStorage 5-10 MB limit** · รูปทรัพย์ต้อง migrate ไป cloud storage
- **PIN auth ไม่ใช่ real auth** · anon key ใช้ RLS open-write · **จะแก้เมื่อทำ RBAC (Phase 1)**
- **buildN8NPayload** ต้องมี `owners` array · เคยลืมทำ Sheet ว่าง
- **`_orphan` flag pattern** · ห้าม hard-delete · mark orphan แทน

---

## 💾 DATA LOSS INCIDENT LOG

- **2026-08-19T13:34:37** · Leads/Deals/Contracts = 0 ทั้ง local + cloud · เกิดขณะแก้ LINE send · root cause ไม่ชัด · user recover ได้ · เพิ่ม `save()` sanity check ป้องกันซ้ำ (`4d0c6e2`)

---

## 📁 KEY FILES

- `index.html` — ทั้งแอป · แก้เฉพาะที่จำเป็น · commit ทันที
- `wrangler.toml` — Cloudflare Pages CLI config
- `.gitignore` — กัน node_modules commit
- `docs/PROJECT_STATUS.md` — **ไฟล์นี้** · handoff / status board
- `docs/SYSTEM_BLUEPRINT.html` — Architecture visual
- `docs/PROPERTY_OPTIMIZATION_AUDIT.md` — Property form spec
- `docs/SUPABASE_STORAGE_SETUP.md` — Legacy (จะเปลี่ยนเป็น R2)
- `docs/SUPABASE_STORAGE_RLS.sql` — Legacy RLS
- `docs/ADVISOR_RENTAL_CARE.md` — Advisor + Rental Care spec
- `docs/GOOGLE_DRIVE_SETUP.md` — Legacy Drive integration

---

## 🎯 QUICK-START สำหรับ AI แชทใหม่

1. **อ่านไฟล์นี้จบก่อน** — จะรู้สถานะทั้งหมด
2. **อ่าน CRITICAL RULES** — ห้ามทำอะไรที่ break rules
3. **ตรวจ commit ล่าสุด:** `git log --oneline -20`
4. **ถามผู้ใช้ว่าจะทำอะไร** — อย่าเดา
5. **แก้เสร็จ → commit ทันที** — format `<area> · <action> · <detail>`
6. **Deploy:** `wrangler pages deploy . --project-name=shelter-crm --branch=main` (เมื่อ Wrangler setup แล้ว) · หรือ `git push` (ทางเดิม)
7. **จบงาน → update ไฟล์นี้:** ย้าย task Pending → Done · เพิ่ม issue ใหม่ · เพิ่ม session log
8. **ทุกงานคิด RBAC** — ถามตัวเองว่า "role ไหนควรเห็น / ทำได้"

---

## 📝 SESSION LOG (append เท่านั้น · ล่าสุดอยู่บน)

### 2026-08-20 · Session 2 (Opus 4.7)
- ✅ Stack decision: Neon + R2 + Wrangler CLI (replace Supabase gradually)
- ✅ สร้าง wrangler.toml + .gitignore
- ✅ สอน R2 setup (6 steps + Worker upload proxy code)
- ✅ สอน Wrangler CLI setup (7 steps)
- ✅ RBAC Upgrade Plan · 6 roles + 5 phases + function-by-function map
- ✅ MCP + CLI Toolchain plan (Cloudflare/Neon/GitHub MCP + wrangler/neonctl/gh CLI)
- ✅ Memory saved: [[project-shelter-stack]], [[feedback-neon-project-creation]], [[project-shelter-rbac]]
- ⏳ Waiting: user install Node.js + CLIs + MCP servers → then AI can automate R2/Neon setup

### 2026-08-20 · Session 1
- ✅ Rental commission other-channel = 1 month rent (`1380b37`)
- ✅ LINE desktop-aware · remove blocking alert (`be4a126`)
- ✅ สร้าง PROJECT_STATUS.md (`2c53fd2`)

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
