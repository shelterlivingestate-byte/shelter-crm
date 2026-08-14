# Google Drive Integration Setup

**เป้าหมาย:** ย้ายรูปภาพทรัพย์จาก localStorage → Google Drive 200GB · ประหยัด localStorage 99%

## Overview Flow

```
[CRM] → POST {propCode, filename, base64} → [n8n webhook]
      → [Google Drive API] uploads to /SHELTER PROPERTY IMAGES/{propCode}/{filename}
      → returns {url} → [CRM] stores URL in p.photos[]
```

## Setup 1 · Google Cloud + Drive Folder (10 นาที)

1. เข้า https://console.cloud.google.com → สร้าง Project ใหม่ (หรือใช้ที่มี)
2. **Enable APIs:**
   - Google Drive API
3. **Create Service Account:**
   - IAM & Admin → Service Accounts → CREATE SERVICE ACCOUNT
   - Name: `shelter-crm-drive`
   - Role: (ไม่ต้องเลือก · ให้สิทธิ์ผ่าน Drive folder แทน)
   - CREATE → done
4. **Download Service Account Key:**
   - เข้า Service Account ที่สร้าง → tab KEYS → ADD KEY → JSON
   - จะได้ไฟล์ `.json` ↓ save ไว้ (จะใช้ใน n8n)
   - **copy email ของ SA** (เช่น `shelter-crm-drive@...iam.gserviceaccount.com`)
5. **สร้าง Drive Folder:**
   - เข้า https://drive.google.com
   - สร้าง folder ชื่อ `SHELTER PROPERTY IMAGES`
   - Right-click → Share → paste email ของ SA · role: **Editor**
   - copy Folder ID จาก URL (ส่วนหลัง `/folders/`)

## Setup 2 · n8n Workflow (5 นาที)

1. เข้า n8n instance ของคุณ (เช่น https://n8n.shelterlivingestate.tech)
2. **Create credential:**
   - Credentials → Add → Google Drive OAuth2 / Service Account
   - เลือก "Service Account" → paste JSON ที่ download มา
   - Save
3. **Import workflow:**
   - Menu → Import from File → paste JSON ด้านล่าง
4. **Configure workflow nodes:**
   - **Webhook node:** copy path (จะเป็น URL: `https://n8n.<your-domain>/webhook/drive-upload`)
   - **Google Drive node:** เลือก credential ที่สร้าง · set parent folder = Folder ID ของ `SHELTER PROPERTY IMAGES`
5. **Activate workflow** (toggle บน-ขวา)
6. **Test:** POST ไปที่ webhook URL ด้วย `{"propCode":"TEST","filename":"test.jpg","base64":"data:image/jpeg;base64,/9j/4AAQ..."}` → ควรได้ response `{"url":"..."}`

## Setup 3 · CRM (1 นาที)

1. เปิด CRM → เมนู **จัดการข้อมูล**
2. หากล่องเขียว **"🚀 ย้ายรูปไป Google Drive"**
3. Paste **Webhook URL** จาก n8n (จากขั้น 2.4)
4. กด **บันทึก URL**
5. กด **🚀 ย้ายรูปเก่าไป Drive** → ระบบจะย้ายทีละรูป (แต่ละรูป ~2-4 วิ · 100 รูป ~5-10 นาที)
6. หลังเสร็จ · **localStorage เบาลงมาก** · save ได้ปกติ

## n8n Workflow JSON (Copy → Import)

```json
{
  "name": "SHELTER · Drive Upload",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "drive-upload",
        "responseMode": "responseNode"
      },
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1,
      "position": [200, 300]
    },
    {
      "parameters": {
        "functionCode": "const body = items[0].json.body || items[0].json;\nconst propCode = String(body.propCode || 'UNKNOWN').replace(/[^A-Za-z0-9_-]/g,'_');\nconst filename = String(body.filename || ('photo_' + Date.now() + '.jpg')).replace(/[^A-Za-z0-9._-]/g,'_');\nlet b64 = body.base64 || '';\nconst m = b64.match(/^data:([^;]+);base64,(.+)$/);\nif (!m) throw new Error('invalid base64 data URI');\nconst mimeType = m[1];\nconst pure = m[2];\nreturn [{ json: { propCode, filename, mimeType }, binary: { data: { data: pure, mimeType, fileName: filename } } }];"
      },
      "name": "Parse base64 → Binary",
      "type": "n8n-nodes-base.function",
      "typeVersion": 1,
      "position": [400, 300]
    },
    {
      "parameters": {
        "operation": "search",
        "queryString": "={{ \"mimeType='application/vnd.google-apps.folder' and name='\" + $json.propCode + \"' and '<PARENT_FOLDER_ID>' in parents and trashed=false\" }},"
      },
      "name": "Find propCode folder",
      "type": "n8n-nodes-base.googleDrive",
      "typeVersion": 3,
      "position": [600, 200],
      "credentials": { "googleDriveOAuth2Api": { "id": "REPLACE", "name": "SHELTER Drive SA" } }
    },
    {
      "parameters": {
        "operation": "create",
        "resource": "folder",
        "name": "={{ $json.propCode }}",
        "parents": ["<PARENT_FOLDER_ID>"]
      },
      "name": "Create folder if missing",
      "type": "n8n-nodes-base.googleDrive",
      "typeVersion": 3,
      "position": [800, 200]
    },
    {
      "parameters": {
        "operation": "upload",
        "name": "={{ $json.filename }}",
        "binaryPropertyName": "data",
        "parents": ["={{ $json.folderId }}"]
      },
      "name": "Upload file",
      "type": "n8n-nodes-base.googleDrive",
      "typeVersion": 3,
      "position": [1000, 300]
    },
    {
      "parameters": {
        "operation": "share",
        "fileId": "={{ $json.id }}",
        "role": "reader",
        "type": "anyone"
      },
      "name": "Make public",
      "type": "n8n-nodes-base.googleDrive",
      "typeVersion": 3,
      "position": [1200, 300]
    },
    {
      "parameters": {
        "respondWith": "json",
        "responseBody": "={ \"url\": \"https://drive.google.com/uc?export=view&id=\" + $node[\"Upload file\"].json.id, \"id\": $node[\"Upload file\"].json.id, \"folderId\": $node[\"Upload file\"].json.parents[0] }"
      },
      "name": "Respond",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [1400, 300]
    }
  ],
  "connections": {
    "Webhook": { "main": [[{ "node": "Parse base64 → Binary", "type": "main", "index": 0 }]] },
    "Parse base64 → Binary": { "main": [[{ "node": "Find propCode folder", "type": "main", "index": 0 }]] },
    "Find propCode folder": { "main": [[{ "node": "Create folder if missing", "type": "main", "index": 0 }]] },
    "Create folder if missing": { "main": [[{ "node": "Upload file", "type": "main", "index": 0 }]] },
    "Upload file": { "main": [[{ "node": "Make public", "type": "main", "index": 0 }]] },
    "Make public": { "main": [[{ "node": "Respond", "type": "main", "index": 0 }]] }
  }
}
```

**⚠ ก่อน import · replace 2 ค่านี้:**
1. `<PARENT_FOLDER_ID>` × 2 ที่ · ใส่ Folder ID ของ `SHELTER PROPERTY IMAGES`
2. `credentials.googleDriveOAuth2Api.id` · ให้ n8n เลือกใหม่ผ่าน UI หลัง import

## หมายเหตุ

- **Public URL** ที่ได้ (`https://drive.google.com/uc?export=view&id=...`) ทุกคนที่มี link เข้าได้ · เหมาะสำหรับรูปทรัพย์ที่จะแสดงใน CRM
- ถ้าไม่อยากให้ public · เปลี่ยน node "Make public" role เป็น "reader" + type "user" + ระบุ email แต่ละคน
- **Migration ทำครั้งเดียว** · หลังจากนั้นรูปใหม่ที่อัปโหลดใน CRM ยัง base64 อยู่ (ต้อง run migration ซ้ำ) · **Phase 3B** จะแก้ให้อัปโหลดตรง Drive เลย

## Rollback

- ถ้า migration ผิดพลาด · รูปในทรัพย์ที่ยังไม่ย้าย (base64) ไม่กระทบ
- Cloud (Supabase) ยัง sync ทุกอย่าง · ถ้าอยากได้ base64 กลับ · restore จาก Export หรือ Supabase snapshot
