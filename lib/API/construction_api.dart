import 'dart:convert';
import 'All_api.dart'; // 引入共用 API

/// 工地 (Site) 相關 API 服務
///
/// Base URL: `/api/Site`
class ConstructionApiService {
  /// 1. 新增工地與相關資源
  ///
  /// 用於建立一筆新的工地資料，並可同時帶入相關的附件資源（如圖片、PDF 等）。
  /// - **Endpoint**: `POST /api/Site/InsertNewSite`
  /// - **說明**: 使用交易機制確保資料一致性。
  ///
  /// ### 參數:
  /// - `teamUUID`: [String] 團隊唯一識別碼 (必填)
  /// - `uploadMemberUUID`: [String] 操作人員唯一識別碼 (必填)
  /// - `siteName`: [String] 工地名稱 (必填)
  /// - `siteAddress`: [String?] 工地地址
  /// - `siteOwner`: [String?] 業主姓名
  /// - `siteOwnerPhoneNumber`: [String?] 業主電話
  /// - `siteClient`: [String?] 客戶姓名
  /// - `siteClientPhoneNumber`: [String?] 客戶電話
  /// - `price`: [int?] 金額
  /// - `siteOrderBegeingDate`: [String?] 預定開始日期 (格式: "YYYY-MM-DDTHH:mm:ss")
  /// - `siteOrderExecuteTime`: [int?] 預定執行天數/時間
  /// - `siteProperty`: [String?] 工地屬性
  /// - `note`: [String?] 備註說明
  /// - `sources`: [List<Map<String, String>>?] 相關資源列表。
  ///   - `sourceType`: 資源類型 (例如："image", "pdf")
  ///   - `source`: 檔案的 Base64 編碼字串
  ///   - `note`: 資源備註
  ///
  /// ### 回傳:
  /// - `(String? errorMessage, Map<String, dynamic>? data)`
  ///   - `errorMessage`: 成功時為 `null`，失敗時為錯誤訊息。
  ///   - `data`: 成功時為後端回傳的新工地資料。
  static Future<(String? errorMessage, Map<String, dynamic>? data)> insertNewSite({
    required String teamUUID,
    required String uploadMemberUUID,
    required String siteName,
    String? siteAddress,
    String? siteOwner,
    String? siteOwnerPhoneNumber,
    String? siteClient,
    String? siteClientPhoneNumber,
    int? price,
    String? siteOrderBegeingDate,
    int? siteOrderExecuteTime,
    String? note,
    List<Map<String, String>>? sources,
  }) async {
    try {
      final payload = {
        "teamUUID": teamUUID,
        "uploadMemberUUID": uploadMemberUUID,
        "siteName": siteName,
        if (siteAddress != null) "siteAddress": siteAddress,
        if (siteOwner != null) "siteOwner": siteOwner,
        if (siteOwnerPhoneNumber != null) "siteOwnerPhoneNumber": siteOwnerPhoneNumber,
        if (siteClient != null) "siteClient": siteClient,
        if (siteClientPhoneNumber != null) "siteClientPhoneNumber": siteClientPhoneNumber,
        if (price != null) "price": price,
        if (siteOrderBegeingDate != null) "siteOrderBegeingDate": siteOrderBegeingDate,
        if (siteOrderExecuteTime != null) "siteOrderExecuteTime": siteOrderExecuteTime,
        if (note != null) "note": note,
        "sources": sources ?? [],
      };

      final response = await BaseApi.post('/Site/InsertNewSite', payload);
      print('API Response Body: ${response.body}');
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (null, decoded['data'] as Map<String, dynamic>?);
      } else {
        return (decoded['message']?.toString() ?? '新增失敗，錯誤碼：${response.statusCode}', null);
      }
    } catch (e) {
      return ('無法連線至伺服器：$e', null);
    }
  }

  /// 2. 根據團隊 UUID 取得所有工地列表
  ///
  /// - **Endpoint**: `GET /api/Site/GetSite/{teamUUID}` (此為推斷，請與後端確認)
  ///
  /// ### 參數:
  /// - `teamUUID`: [String] 團隊唯一識別碼
  ///
  /// ### 回傳:
  /// - `List<Map<String, dynamic>>?`: 成功時回傳工地列表，失敗或無資料時回傳 `null` 或空列表。
  static Future<List<Map<String, dynamic>>?> getSitesByTeam(String teamUUID) async {
    try {
      // 根據您的 home_page.dart 推斷，您需要一個透過 teamUUID 取得工地列表的 API
      // 請與後端確認實際的 Endpoint 路徑
      final response = await BaseApi.get('/Site/GetSitesByTeam/$teamUUID');
      print('[ConstructionApiService] getSitesByTeam - URL: /Site/GetSitesByTeam/$teamUUID');
      print('[ConstructionApiService] getSitesByTeam - Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        dynamic data = decoded;

        // 處理後端可能將資料包裝在 'data' 屬性內的情況
        if (decoded is Map && decoded.containsKey('data')) {
          data = decoded['data'];
        }

        print('[ConstructionApiService] getSitesByTeam - Decoded Data: $data');
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        print('[ConstructionApiService] getSitesByTeam - Data is not a List, returning empty.');
        return []; // 成功但無資料
      }
      print('[ConstructionApiService] getSitesByTeam - API call failed or status not 200.');
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 3. 根據工地 UUID 取得單筆工地詳細資料
  ///
  /// - **Endpoint**: `GET /api/Site/GetSiteDetail/{siteUUID}`
  ///
  /// ### 參數:
  /// - `siteUUID`: [String] 工地唯一識別碼
  ///
  /// ### 回傳:
  /// - `Map<String, dynamic>?`: 成功時回傳包含 `siteInfo` 和 `sources` 的完整工地資料，失敗時回傳 `null`。
  static Future<Map<String, dynamic>?> getSiteDetail(String siteUUID) async {
    try {
      final response = await BaseApi.get('/Site/GetSiteDetail/$siteUUID');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // 後端資料通常會包在 'data' 屬性裡
        return decoded['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('取得工地詳細資料失敗: $e');
      return null;
    }
  }
}