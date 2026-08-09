# SHELTER CRM — ID Map

> Central ID reference · หลักการ **1 entity = 1 ID เท่านั้น** ห้ามใช้ชื่อ/เบอร์/รหัสโครงการเป็น primary key
> อัปเดตล่าสุด: 2026-08-09 · เพิ่มโดย Phase 0
> ต้องอัปเดตทุกครั้งที่เพิ่ม ID/relationship ใหม่

## กติกา

1. **ID ทุกตัวสร้างจาก `uid()`** — `"id" + base36(Date.now()) + base36(Math.random()*1e5)` → ไม่ซ้ำระหว่างอุปกรณ์ (มีโอกาสน้อยมากที่จะชน)
2. **ห้ามอ้างอิงข้าม entity ด้วยชื่อ** — ใช้ ID เท่านั้น
3. **ห้ามลบ ID** — mark สถานะแทน (`status: "archived"` เป็นต้น)
4. **Migration ไม่ล้าง ID เดิม** — ถ้าต้อง merge, เก็บ mapping `old_id → new_id` ไว้ใน alias table

## 10 IDs กลาง

| ID | เก็บที่ | อ้างอิงจาก | หมายเหตุ |
|---|---|---|---|
| **Property ID** | `props[].id` | `deals.propertyId`, `contracts.propertyId`, `mkt.propertyId`, `appointments.propertyId`, `competitors.propertyId`, `ownerReports.propertyId`, `expense.propertyId`, `income.propertyId` | ทรัพย์ทุกหลัง 1 ID · ขายและเช่าอยู่ table เดียว แยกด้วย `deal` field |
| **Owner ID** | `owners[].id` | `props.ownerId`, `ownerReports.ownerId`, `ownerLog.ownerId`, `ownerCare.ownerId` | ⚠ ปัจจุบัน migrateOwners() auto-link จาก name+phone — Phase 1 จะแก้ให้ user ยืนยัน |
| **Customer ID** | `leads[].id` | `deals.customerId` (มี `custId` alias legacy), `appointments.customerId`, `contracts.tenantId`, `cons.customerId` | ⭐ **ตัวเชื่อมหลัก** ตาม comment ในโค้ด (บรรทัด 1347) · Buyer, Tenant, Seller, Landlord อยู่ table `leads` เดียวกัน แยกด้วย `ltype` |
| **Buyer ID** | (ไม่แยก — ใช้ Customer ID) | — | Filter `leads` where `ltype="ซื้อ"` · view `leadsBuy` |
| **Tenant ID** | (ไม่แยก — ใช้ Customer ID) | `contracts.tenantId` | Filter `leads` where `ltype="เช่า"` · view `leadsRent` |
| **Project ID** | `projects[].id` | `props.projectId`, `competitors.competitorProjectId` | Projects Database · ใช้ match tier "โครงการเดียวกัน" ใน competitor logic |
| **Deal ID** | `deals[].id` | `contracts.dealId`, `finance.dealId`, `income.dealId`, `expense.dealId` | Deal Pipeline · connects customer + property + financial records |
| **Contract ID** | `contracts[].id` | `rentLedger.contractId`, `rentalCommissions.contractId`, `rentTasks.contractId`, `repairs.contractId`, `inspections.contractId`, `tenantCare.contractId` | ตัวรวมของ Rental world |
| **Appointment ID** | `appointments[].id` | — (ไม่มี back-reference ใน DB — ok, อ้างจาก Customer/Property) | Standalone entity |
| **Activity ID** | (ยังไม่มี — Phase 3 สร้างตาราง `activities`) | จะรวม `ownerLog`, `auditLog`, appointment results | Phase 3 |

## Relationships (แผนภาพความสัมพันธ์)

```
Project ──1:N──▶ Property
                    │
                    ├──N:1──▶ Owner
                    │
                    ├──1:N──▶ Marketing (mkt)
                    │
                    ├──1:N──▶ Competitor
                    │
                    ├──1:N──▶ Deal ──N:1──▶ Customer (leads)
                    │           │
                    │           └──1:N──▶ Contract
                    │                       │
                    │                       ├──N:1──▶ Tenant (leads)
                    │                       │
                    │                       ├──1:N──▶ RentLedger
                    │                       ├──1:N──▶ RentalCommission
                    │                       ├──1:N──▶ RentTask
                    │                       ├──1:N──▶ Repair
                    │                       ├──1:N──▶ Inspection
                    │                       └──1:N──▶ TenantCare
                    │
                    ├──1:N──▶ Appointment ──N:1──▶ Customer
                    │
                    ├──1:N──▶ OwnerReport
                    │
                    ├──1:N──▶ Income
                    ├──1:N──▶ Expense
                    └──1:N──▶ Finance
                    
Owner ──1:N──▶ OwnerLog / OwnerCare
```

## จุดที่ยังไม่เป็น ID (ต้องแก้ใน Phase ถัดไป)

| จุด | ปัจจุบัน | Phase | หมายเหตุ |
|---|---|---|---|
| `deals.prop` | ข้อความ (fallback ถ้าไม่มี `propertyId`) | Phase 1 | `propOfDeal()` fuzzy-match ชื่อ — เลิกใช้ทั้งระบบ ให้ `propertyId` เป็นบังคับ |
| `props.ownerName` / `.ownerPhone` / `.ownerLine` | ข้อความ legacy | Phase 1 | เก็บไว้ backward-compat แต่ `ownerId` เป็นแหล่งความจริง (`ownerOf()` เอา `ownerId` ก่อน) |
| `deals.custId` | Alias เก่าของ `customerId` | Phase 1 | Migrate ทุก record ใช้ `customerId` เท่านั้น (alias อ่านได้ 1 release แล้วเลิก) |
| `leads.ltype` | Single-value journey | Phase 2 | ขยายเป็น `leads.journeys[]` = multi-value (buy, rent, sell, let, invest) |

## กระบวนการเมื่อสร้าง entity ใหม่

```
1. เรียก uid() → ได้ new ID
2. ตั้ง obj.id = new ID
3. ตั้ง obj.createdAt = todayISO()
4. Push เข้า DB.<key>
5. เรียก save() → localStorage + auto-backup + schedule cloud push
```

## กระบวนการเมื่ออ้างอิง entity อื่น

```
✅ อ้างอิงด้วย .propertyId, .ownerId, .customerId, .contractId, ...
❌ ห้ามอ้างอิงด้วย .propName, .ownerName, .customerName เป็น primary lookup

✅ ownerOf(prop) — ใช้ ownerId ก่อน · fallback ownerName/ownerPhone (Phase 1 จะตัด fallback)
✅ propOfDeal(deal) — ใช้ propertyId ก่อน · Phase 1 ตัด text fallback
```
