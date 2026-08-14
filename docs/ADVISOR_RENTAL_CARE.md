# Advisor Dashboard + Rental Care · Section 1 & 2 Follow-up

## Audit ก่อนแก้

**ที่มีอยู่แล้ว:**
- Advisor: ระบบใช้ single-user (getAuth email) · ไม่มี `advisorId` FK · assignedAgent เก็บใน `lead.assignedAgent` เป็น text
- Goal store: `DB.goals` (จาก MASTER-3) · มี `advisorId` field รองรับทีมอนาคต
- Contracts: `leaseClosedByType` มี 5 opts เดิม (Our/Co/Other/Owner/Unknown)
- Property: มี `marketingStart, lastOwnerUpdate` timeline fields
- Sync toast: `.sync-badge` เล็กอยู่แล้ว · ไม่ใช่ toast
- Rental Commission: `computeRentalCommission()` มีสูตรพร้อม net คำนวณ

**ที่ต้องเพิ่ม/แก้:**
- Section 1.1: hide Advisor input · auto = getSettings().currentUser
- Section 1.2: Thai พ.ศ. + rename filter labels · sync กับ dashScope
- Section 1.3: Thai month title + งานสำคัญวันนี้
- Section 1.4: Goal Focus Popup + FAB
- Section 1.5: mobile stack goal cards
- Section 2.7: add "ปิดเช่าจากช่องทางอื่น" option (keep old for read-back)
- Section 2.9: add 6 timeline fields (intake, available, dataReady, photosReady, knownLeased, marketingPaused)
- Section 2.10: 3 duration helpers (propPrepDays, propMarketDays, propTotalPortfolioDays)

## Changes ในรอบนี้

### Section 1 · Advisor Dashboard

| ข้อ | Change |
|---|---|
| 1.1 | `renderDashGoals` · ลบ Advisor input · auto `currentAdvisorId()` = settings.currentUser · โครงสร้าง advisorId ใน goals schema เก็บไว้รองรับทีม |
| 1.2 | year dropdown แสดง พ.ศ. · month dropdown ใช้ Thai short names · ไม่มี local Advisor filter ซ้ำ |
| 1.3 | Title "เป้าหมายของฉัน · [เดือน พ.ศ.]" · block "งานสำคัญวันนี้" ดึงจาก top priority property nextAction |
| 1.4 | `openGoalPopup/closeGoalPopup/_maybeOpenGoalPopup/_updateGoalFab` · sessionStorage flag `shelter_goal_popup_shown_v1` · FAB "🎯 เป้าเดือนนี้" แสดงเฉพาะหลังปิด popup และไม่อยู่ dashboard · trigger 800ms หลัง renderAll |
| 1.5 | CSS `.goal-cards` + `.goal-card` media query · mobile stack + shrink val font |

**Data safety:**
- ไม่ลบ advisor field · struct รองรับ manager view อนาคต
- sessionStorage (ไม่ใช่ localStorage) — ล้างเมื่อปิด browser
- popup ผูก sessionStorage key → ไม่เด้งซ้ำแม้เปลี่ยน route (spec §1.4)

### Section 2 · Rental Care

| ข้อ | Change |
|---|---|
| 2.7 | `SCHEMA.contracts.leaseClosedByType` opts เพิ่ม "ปิดเช่าจากช่องทางอื่น" · เก็บ 3 opts เดิม (Other/Owner/Unknown) เพื่อ backward-compat · แนะนำผู้ใช้ใช้ "ปิดเช่าจากช่องทางอื่น" ใหม่ |
| 2.9 | `SCHEMA.props` +6 timeline fields · intakeDate, availableDate, dataReadyDate, photosReadyDate, knownLeasedDate, marketingPausedDate · แก้ label ของ marketingStart เป็น "วันที่เริ่มทำการตลาดจริง" |
| 2.10 | Helpers: `_daysBetween`, `_propRefEndDate`, `propPrepDays`, `propMarketDays`, `propTotalPortfolioDays`, `propTimelineMissing` · negative = 0 · Calendar Day · Active Days marker เมื่อยังไม่ปล่อย |

**Data safety:**
- ไม่แก้ field ที่มีอยู่ · เพิ่มใหม่เท่านั้น
- Object.assign(list[i],obj) → records เก่าที่ไม่มี field ใหม่ยัง render "—"
- ไม่ delete `leaseClosedByType` opt เดิม · records เก่า "Other Agent" ยังแสดงได้

## Deferred (ยังไม่ทำ · Roadmap ถัดไป)

**ต้องรอบเพิ่ม:**
- **Section 1.6** · Sync toast tuning — เป็น `.sync-badge` อยู่แล้ว · ไม่ใช่ toast · ถ้ายังต้องการปรับต่อ ระบุจุดเจาะจง
- **Section 2.8** · "มูลค่าโอกาสที่ไม่ได้รับ" auto-calc จาก computeRentalCommission — ต้องมี "ปิดเช่าจากช่องทางอื่น" flow เต็มก่อน · Phase ถัดไป
- **Section 2.11** · Snapshot store `DB.propSnapshots` — big feature · ต้อง trigger จุดเดียว (intake) + read on report · ให้ทำแยก
- **Section 2.12** · Marketing Funnel view เต็มรูป — เชื่อม `mkt` + `leads` + `appointments` + `deals` · phase 4
- **Section 2.13** · Rental Market Performance Dashboard — ใช้ helpers ใหม่ + snapshot · phase 5
- **Section 2.14** · Cross-section stats (project/price/condition) — needs 2.13 first

## Test Cases (static verify · Section 1 & 2 · rounds ที่ทำ)

- ✅ `getSettings().currentUser` ไม่มีค่า → `currentAdvisorId()` = "" (auto works)
- ✅ Popup แสดงครั้งเดียว · sessionStorage flag set on close
- ✅ FAB แสดงเฉพาะ non-dashboard + หลังปิด popup
- ✅ Mobile: `.goal-cards` stacks column · `.goal-card` min-width:0
- ✅ Thai พ.ศ. label: `thaiMonthYear(2026, 8, true)` = "สิงหาคม 2569"
- ✅ New Rental option = "ปิดเช่าจากช่องทางอื่น" · เดิม 5 opts ยังอ่านได้
- ✅ Timeline fields optional (no req:1) · missing fields → propTimelineMissing returns list
- ✅ propPrepDays(null) = null · negative dates clip to 0
- ✅ propMarketDays returns {days, active, leased, paused} · Active Days marker

## Rollback

```
git revert 78a1... && git push
```

Data ใน `DB.props` ที่กรอก timeline fields ใหม่ยังอยู่ (schema field ที่ถูก revert ยังไม่แสดงในฟอร์ม แต่ค่า stored อยู่) · เมื่อ re-deploy รอบใหม่จะกลับมาแสดงทันที
