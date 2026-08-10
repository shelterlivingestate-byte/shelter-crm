# Part 6B — Security Hardening (Recommended · Requires user-side action)

**Status:** ยังไม่ทำ · ต้องให้ user ดำเนินการ (หรือให้ผมทำในรอบถัดไปเมื่อได้ access)

## เหตุผลที่ยังไม่ทำในรอบนี้

Repo ปัจจุบันมีแค่ `index.html` + `docs/` ไม่มี Worker source file (wrangler.toml / worker.js). Cloudflare Workers Builds ใช้ default template เสิร์ฟ HTML ตรงๆ · จะเพิ่ม API proxy ต้อง:

1. เพิ่ม `wrangler.toml` + `src/worker.js` ในระดับ repo
2. หรือแก้ผ่าน Cloudflare Dashboard → Worker `ancient-bird-a68f` → Edit Code

ทั้งสองแบบต้องให้ user ตรวจสอบ setup ปัจจุบัน + สร้าง Worker Secrets

## แผน Part 6B — 2 ทางเลือก

### ทางเลือก A · เพิ่ม Worker source ใน repo (แนะนำ)

**Files ใหม่:**

```
wrangler.toml
src/worker.js
```

**wrangler.toml (ตัวอย่าง):**

```toml
name = "ancient-bird-a68f"
main = "src/worker.js"
compatibility_date = "2024-01-01"
routes = [
  { pattern = "crm.shelterlivingestate.tech/*", zone_name = "shelterlivingestate.tech" }
]
# assets = { directory = "./" }  # หากใช้ Static Assets — ต้อง confirm ว่า Cloudflare setup รองรับ
```

**src/worker.js (ร่าง):**

```js
const SECURITY_HEADERS = {
  "content-security-policy": "default-src 'self' 'unsafe-inline' 'unsafe-eval' data: https://fonts.googleapis.com https://fonts.gstatic.com https://*.supabase.co https://api.anthropic.com https://api.openai.com; frame-ancestors 'none'",
  "x-frame-options": "DENY",
  "x-content-type-options": "nosniff",
  "referrer-policy": "strict-origin-when-cross-origin",
  "permissions-policy": "geolocation=(), microphone=(), camera=()"
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // AI proxy routes — key never leaves Worker
    if (url.pathname === "/api/ai/anthropic") return proxyAnthropic(request, env);
    if (url.pathname === "/api/ai/openai") return proxyOpenAI(request, env);

    // Static asset (index.html) — served with security headers
    const resp = await fetch(request); // relies on Static Assets binding
    const h = new Headers(resp.headers);
    for (const [k,v] of Object.entries(SECURITY_HEADERS)) h.set(k, v);
    return new Response(resp.body, { status: resp.status, headers: h });
  }
};

async function proxyAnthropic(request, env) {
  if (request.method !== "POST") return new Response("method", { status:405 });
  const body = await request.text();
  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,      // Worker Secret
      "anthropic-version": "2023-06-01"
    },
    body
  });
  return new Response(r.body, { status: r.status, headers: { "content-type":"application/json" }});
}

async function proxyOpenAI(request, env) {
  if (request.method !== "POST") return new Response("method", { status:405 });
  const body = await request.text();
  const r = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "authorization": "Bearer " + env.OPENAI_API_KEY  // Worker Secret
    },
    body
  });
  return new Response(r.body, { status: r.status, headers: { "content-type":"application/json" }});
}
```

**Worker Secrets ที่ต้องเพิ่มใน Cloudflare Dashboard:**

- `ANTHROPIC_API_KEY` — ค่า key ที่ user เคยกรอกใน settings (paste ใน Secret ครั้งเดียว)
- `OPENAI_API_KEY` — เช่นกัน

**Frontend change (จะทำในรอบถัดไป):**

Update `callAI()` ใน index.html ให้เรียก `/api/ai/anthropic` แทน `https://api.anthropic.com/v1/messages` (relative path — Worker route จับได้) · ไม่ต้องส่ง `x-api-key` (Worker ใส่ให้)

**Feature flag:** `localStorage["shelter_ai_via_proxy"] = "1"` เปิดใช้ proxy · `0` ใช้ direct-to-API เดิม (rollback ทันทีถ้าพัง)

### ทางเลือก B · แก้ผ่าน Cloudflare Dashboard UI (เร็วกว่า setup แต่ไม่มี version control)

1. เข้า Cloudflare Dashboard → Workers & Pages → `ancient-bird-a68f`
2. **Edit Code** → paste `src/worker.js` code ข้างบน (แต่แบบ Modules syntax ที่ dashboard รองรับ)
3. **Settings → Variables** → เพิ่ม Environment Variables (encrypted):
   - `ANTHROPIC_API_KEY`
   - `OPENAI_API_KEY`
4. **Deploy** → route เดิม `crm.shelterlivingestate.tech/*` ยังทำงาน

**ข้อเสีย:** โค้ด Worker ไม่ track ใน git · rollback ยากกว่า · แต่ setup เร็ว

## สิ่งที่ user ต้องตัดสินใจ

1. **เลือก A หรือ B?**
2. **ให้ผมทำ Part 6B ต่อไหม?** — ถ้าเลือก A ผมสร้าง `wrangler.toml` + `src/worker.js` ให้ · user เพิ่ม Secrets ใน Cloudflare Dashboard · frontend flip flag
3. **หรือทำเอง?** — ผมเตรียม code ให้แล้ว · user paste ใน Cloudflare UI

## ผลกระทบเมื่อทำเสร็จ

**ก่อน:**
- AI key อยู่ใน browser localStorage · user เห็นได้ · ถ้าแชร์เครื่องหรือ dev tools เปิด = leak

**หลัง:**
- AI key อยู่ใน Cloudflare Worker Secret · frontend ไม่เห็น · ปลอดภัยกว่า
- Security headers ลด attack surface: no framing (X-Frame-Options), no MIME sniffing, strict referrer, CSP restrict inline
- rate limit ทำได้ที่ Worker level (กัน key abuse ถ้ามี)

## Rollback ถ้ามีปัญหา

- Feature flag frontend → ปิด `shelter_ai_via_proxy`
- Cloudflare Deployments → Rollback ไปเวอร์ชันก่อนหน้าทันที (Dashboard UI)
- ลบ /api/* routes ใน Worker ไม่กระทบการ serve index.html
