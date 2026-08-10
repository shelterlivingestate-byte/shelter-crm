# Marketing Merge — Notes

**Commit:** initial · **Status:** live

## Concept

Two legacy pages merged into one unified `การตลาดและการลงประกาศ` (`#v-marketing`):

- ~~`#v-mkt` (Marketing Engine)~~ → `hidden:true` in module registry · redirected via `go()`
- ~~`#v-propMkt` (ข้อมูลการตลาด / Property Marketing)~~ → `hidden:true` · redirected

Legacy HTML views kept in DOM (backward-compat) for 1 release before deletion.

## Single Source of Truth

| Concept | Store | Owner |
|---|---|---|
| **Channel enum (15 platforms)** | `CHANNELS` const | Merge commit — replaces `CHAN_META` (which is now derived) |
| **Per-property URL map** | `p.channels{k:url}` | Property Master (existing) |
| **Campaign + metric records** | `DB.mkt[]` | Marketing Engine schema (existing, Part 4 extended) |
| **Marketing expenses** | `DB.expense[]` (category matches marketing) | Finance module (existing) |
| **Expense ↔ campaign link** | `expense.mktId` (soft link) | **New (DM-5 approved)** |
| **Leads attribution** | `DB.leads.src` (matches CHANNELS.name) | Customer form (existing) |

## Adapters

- `propChannelSync(propId, chKey, url)` — writes both `p.channels[chKey]` and matching `DB.mkt` row (create or update)
- `mktLinkExpense(mktRow, expenseData)` — creates `DB.expense` row with `mktId=mktRow.id` and `propertyId=mktRow.propertyId`
- `migrateMarketingSync()` — runs on load · syncs `p.channels ↔ DB.mkt` (idempotent, additive, no delete)

## Derived helpers (no stored duplicates)

- `mktScopeFilter()` — returns filtered `DB.mkt[]` based on `mktScope` (range, type, channelKey)
- `mktCostOf(items)`, `mktLeadsOf(items)`, `mktApptsOf(items)`, `mktDealsOf(items)`, `mktRevenueOf(items)`
- `cplOf`, `cpaOf`, `cpdOf`, `roiOf` — all return `null` when divisor = 0 → UI shows `—` (no NaN/Infinity)
- `mktTasks()` — derives task list from real data (no separate storage)

## 15 platforms

LivingInsider · PropertyHub · DDproperty · DotProperty · Hipflat · Thailand Property · FazWaz · Baania · TerraBKK · Baan Finder · Proppit/PP+ · Facebook · Instagram · LINE VOOM · Website

**Facebook ≠ DDproperty ≠ DotProperty** — 3 separate entries per spec.

## Fields moved out of Marketing (spec §5)

These live only in Commission/Finance now, not in Marketing UI:

- `mkt.shirtCost` (legacy — kept in schema for backward-compat, hidden in new UI)
- `mkt.fuelCost` (legacy)
- `mkt.consultFee` (legacy)
- `mkt.referralFee` (legacy)

Existing values still readable; new records don't populate these.

## Redirect

`go('mkt')` and `go('propMkt')` → `go('marketing')` with `console.log` deprecation warning.

## Rollback

`git revert <commit> && git push`. Data untouched (all adapters are additive). Sidebar returns to 2 legacy items.
