# EZAssign — Subscription API 文件

**Base path**: `/api/subscripion`

---

## Endpoints

### 1. 建立團隊

**`POST /creatTeam`**

建立一個新的團隊。每位使用者最多可建立 3 個團隊，超過限制將回傳錯誤。

**Request body**

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `GeneratorUUID` | string | ✅ 必填 | 建立者的 UUID |
| `TeamName` | string | ✅ 必填 | 團隊名稱 |
| `TeamUUID` | string | — 自動 | 由資料庫自動產生，毋須傳入 |
| `CreatedDate` | datetime | — 自動 | 由 API 自動填入建立時間 |

**回應狀態碼**

| 狀態碼 | 情境 |
|--------|------|
| 200 | 團隊建立成功 |
| 400 | 缺少必填欄位 / 超過 3 個團隊限制 |

**成功回應範例**

```json
{
  "message": "團隊建立成功",
  "data": {
    "TeamUUID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "GeneratorUUID": "user-uuid-here",
    "TeamName": "My Team",
    "CreatedDate": "2025-01-01T00:00:00"
  }
}
```

---

### 2. 取得使用者所有團隊

**`GET /GetTeams/{userUUID}`**

取得指定使用者所建立的所有團隊列表。

**Path 參數**

| 參數 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `userUUID` | string | ✅ 必填 | 使用者的 UUID |

**回應狀態碼**

| 狀態碼 | 情境 |
|--------|------|
| 200 | 成功，回傳團隊陣列（可為空陣列） |
| 400 | 缺少 `userUUID` |

**成功回應範例**

```json
{
  "message": "取得成功",
  "data": [
    {
      "TeamUUID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "GeneratorUUID": "user-uuid-here",
      "TeamName": "My Team",
      "CreatedDate": "2025-01-01T00:00:00"
    }
  ]
}
```

---

### 3. 取得團隊生效中方案

**`GET /activePlan/{teamUUID}`**

取得指定團隊目前狀態為 `Active` 的訂閱方案，並附帶團隊名稱與剩餘天數。

**Path 參數**

| 參數 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `teamUUID` | string | ✅ 必填 | 目標團隊的 UUID |

**回應狀態碼**

| 狀態碼 | 情境 |
|--------|------|
| 200 | 成功 |
| 400 | 缺少 `teamUUID` |
| 404 | 找不到指定團隊 / 該團隊目前沒有生效中方案 |

**成功回應範例**

```json
{
  "message": "取得成功",
  "data": {
    "LicenseKey": "LICENSE-XXXX",
    "SubscriptionPlan": "1month",
    "TeamUUID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "LicenseStatus": "Active",
    "ActivatedAt": "2025-01-01T00:00:00",
    "ExpiredAt": "2025-02-01T00:00:00"
  },
  "teamName": "My Team",
  "remainingDays": 27.3
}
```

> **備註**：`remainingDays` 已由 API 計算完成（四捨五入至小數點第一位），前端可直接顯示。若方案已過期則回傳 `0`。

---

### 4. 訂閱 / 續約

**`POST /subscribe`**

將授權碼綁定至指定團隊並啟用訂閱。若該團隊已有生效中方案，新方案將從原方案到期日開始計算（自動續約）。舊方案狀態會自動改為 `Upgraded`。

**Request body**

| 欄位 | 型別 | 必填 | 說明 |
|------|------|------|------|
| `TeamUUID` | string | ✅ 必填 | 目標團隊的 UUID |
| `SubscriptionPlan` | string | ✅ 必填 | 訂閱方案代號（見下方允許值） |
| `LicenseKey` | string | ✅ 必填 | 欲啟用的授權碼 |

**允許的 `SubscriptionPlan` 值**

| 值 | 效期 |
|----|------|
| `7day` | 7 天 |
| `14day` | 14 天 |
| `1month` | 1 個月 |
| `3month` | 3 個月 |
| `6month` | 6 個月 |
| `1year` | 1 年 |

**回應狀態碼**

| 狀態碼 | 情境 |
|--------|------|
| 200 | 訂閱成功 / 續約成功 |
| 400 | 缺少必填欄位 / 方案代號不合法 / 授權碼無效或已被使用 / 授權碼方案與請求方案不符 |
| 404 | 找不到指定團隊 |

**成功回應範例**

```json
{
  "message": "訂閱成功",
  "data": {
    "LicenseKey": "LICENSE-XXXX",
    "TeamUUID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "SubscriptionPlan": "1month",
    "LicenseStatus": "Active",
    "ActivatedAt": "2025-01-01T00:00:00",
    "ExpiredAt": "2025-02-01T00:00:00"
  }
}
```

> **備註**：有尚未到期方案時 `message` 為「續約成功」；首次訂閱則為「訂閱成功」。

---

## 資料模型

### `subscriptionlicensebase`

對應資料表：`subscriptionlicensebase`

| 欄位 | 型別 | 說明 |
|------|------|------|
| `LicenseKey` 🔑 | string(50) | 主鍵，由資料庫自動產生 |
| `SubscriptionPlan` | string(50) | 方案代號 |
| `TeamUUID` | string(50)? | 綁定的團隊 UUID（未啟用時為 null） |
| `ActivatedAt` | datetime? | 啟用時間 |
| `ExpiredAt` | datetime? | 到期時間 |
| `LicenseStatus` | string(50)? | `Unused` / `Active` / `Upgraded` |

---

### `teambuildinginfo`

對應資料表：`teambuildinginfo`

| 欄位 | 型別 | 說明 |
|------|------|------|
| `TeamUUID` 🔑 | string(50)? | 主鍵，由資料庫自動產生 |
| `GeneratorUUID` | string(50) | 建立者 UUID |
| `TeamName` | string(50)? | 團隊名稱 |
| `CreatedDate` | datetime? | 建立時間 |

---

### `teamsubscription`

對應資料表：`teamsubscription`

| 欄位 | 型別 | 說明 |
|------|------|------|
| `Index` 🔑 | int | 主鍵，自動遞增 |
| `LicenseKey` | string(50) | 對應的授權碼 |
| `TeamUUID` | string(50) | 對應的團隊 UUID |
