# 📖 EZAssign - 客戶身分 (Identity) API 說明文件

## Base URL

```txt
http://localhost:5243/api/Identity
```

> 如果你的伺服器 Port 有變動，請將 `5243` 替換為實際的 Port。

---

# 1️⃣ 檢查資料庫連線狀態

測試後端是否能成功連線至 MariaDB。

## Request

```http
GET /check-connection
```

## Response - 200 OK

```json
{
  "message": "恭喜!成功連接到 MariaDB 資料庫!"
}
```

---

# 2️⃣ 取得所有客戶資料

撈取 `client_identity` 資料表中的所有紀錄。

## Request

```http
GET /
```

## Response - 200 OK

```json
[
  {
    "index": "uuid",
    "name": "王小明",
    "company": "易派工",
    "position": "主管",
    "phoneNumber": "0912345678"
  }
]
```

---

# 3️⃣ 取得單筆客戶資料

透過主鍵 `Index` 查詢特定客戶。

## Request

```http
GET /{id}
```

### Example

```http
GET /api/Identity/123e4567-e89b-12d3-a456-426614174000
```

## Response - 200 OK

```json
{
  "index": "123e4567-e89b-12d3-a456-426614174000",
  "name": "王小明",
  "company": "易派工",
  "position": "主管"
}
```

## Response - 404 Not Found

```json
{
  "message": "找不到指定的客戶資料"
}
```

---

# 4️⃣ 新增或更新客戶資料 (Upsert)

傳入客戶資料 JSON，系統會自動判斷是：

- 新增資料
- 更新資料

---

## Request

```http
POST /upsert
Content-Type: application/json
```

---

# 📋 欄位規格

| 欄位名稱 | 型別 | 必填 | 說明 |
|---|---|---|---|
| index | string | ❌ | 新增時不需傳入，更新時才需要 |
| name | string | ✅ | 客戶姓名 |
| company | string | ✅ | 公司名稱 |
| position | string | ✅ | 職稱 |
| phoneNumber | string | ✅ | 聯絡電話 |
| iceName | string | ✅ | 緊急聯絡人姓名 |
| icePhoneNumber | string | ✅ | 緊急聯絡人電話 |
| iceRelation | string | ✅ | 緊急聯絡人關係 |
| geneticHistory | string | ❌ | 家族病史 |
| blood | string | ❌ | 血型 |
| gender | string | ❌ | 性別 |
| note | string | ❌ | 備註事項（最多 200 字） |
| birth | datetime | ❌ | 生日（YYYY-MM-DD） |
| email | string | ❌ | 電子信箱 |
| address | string | ❌ | 聯絡地址 |
| picture | byte[] | ❌ | Base64 圖片字串 |

---

# 📝 情境 A：新增客戶

新增時 **不需要傳入 `index`**。

系統會自動產生 UUID。

## Request Body

```json
{
  "name": "陳最簡",
  "company": "易派工",
  "position": "員工",
  "phoneNumber": "0912345678",
  "iceName": "陳爸爸",
  "icePhoneNumber": "0988777666",
  "iceRelation": "父子"
}
```

## Response - 200 OK

```json
{
  "message": "新增成功",
  "data": {
    "index": "自動產生的UUID",
    "name": "陳最簡",
    "company": "易派工",
    "position": "員工",
    "phoneNumber": "0912345678",
    "iceName": "陳爸爸",
    "icePhoneNumber": "0988777666",
    "iceRelation": "父子"
  }
}
```

---

# 📝 情境 B：更新客戶

更新時必須提供既有的 `index`。

## Request Body

```json
{
  "index": "已存在的UUID",
  "name": "陳最簡(已改名)",
  "company": "易派工",
  "position": "主管",
  "phoneNumber": "0912345678",
  "iceName": "陳爸爸",
  "icePhoneNumber": "0988777666",
  "iceRelation": "父子",
  "note": "這是更新時補上的備註"
}
```

## Response - 200 OK

```json
{
  "message": "更新成功",
  "data": {
    "index": "已存在的UUID",
    "name": "陳最簡(已改名)",
    "company": "易派工",
    "position": "主管"
  }
}
```

---

# 5️⃣ 刪除客戶資料

透過主鍵 `Index` 刪除指定客戶。

## Request

```http
DELETE /{id}
```

### Example

```http
DELETE /api/Identity/123e4567-e89b-12d3-a456-426614174000
```

## Response - 200 OK

```json
{
  "message": "刪除成功"
}
```

---

# 🧩 資料模型 (client_identity)

```csharp
public class client_identity
{
    public string? Index { get; set; }

    public string Name { get; set; } = null!;

    public string Company { get; set; } = null!;

    public string Position { get; set; } = null!;

    public string PhoneNumber { get; set; } = null!;

    public string ICEName { get; set; } = null!;

    public string ICEPhoneNumber { get; set; } = null!;

    public string ICERelation { get; set; } = null!;

    public string? GeneticHistory { get; set; }

    public string? Blood { get; set; }

    public string? Gender { get; set; }

    public string? Note { get; set; }

    public DateTime? Birth { get; set; }

    public string? Email { get; set; }

    public string? Address { get; set; }

    public byte[]? Picture { get; set; }
}
```

---

# ✅ 備註

- `Index` 為主鍵，由 MariaDB 自動產生 UUID。
- `Picture` 欄位需使用 Base64 字串傳送。
- `Birth` 日期格式建議使用：

```txt
YYYY-MM-DD
```

例如：

```txt
1999-01-25
```

- `Note` 最大長度為 200 字。
- 所有必填欄位若未提供，API 應回傳驗證錯誤。

---

# 🚀 建議未來擴充

可新增：

- Swagger/OpenAPI
- JWT 驗證
- 圖片上傳 API
- 分頁查詢
- 關鍵字搜尋
- 軟刪除 (Soft Delete)
- 建立時間 / 更新時間欄位
