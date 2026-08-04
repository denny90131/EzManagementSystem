import 'dart:convert';
import 'All_api.dart'; // 引入共用 API

class ConstructionApiService {
  /// 1. 新增工地與相關資源
  ///
  /// 用於建立一筆新的工地資料，並可同時帶入相關的附件資源（如圖片、PDF 等）。
  /// 使用交易機制確保資料一致性。
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
    String? siteProperty,
    String? note,
    List<Map<String, String>>? sources,
  }) async {
    try {
      final payload = {
        "teamUUID": teamUUID,
        "uploadMemberUUID": uploadMemberUUID,
        "siteName": siteName,
        "siteAddress": siteAddress,
        "siteOwner": siteOwner,
        "siteOwnerPhoneNumber": siteOwnerPhoneNumber,
        "siteClient": siteClient,
        "siteClientPhoneNumber": siteClientPhoneNumber,
        "price": price,
        "siteOrderBegeingDate": siteOrderBegeingDate,
        "siteOrderExecuteTime": siteOrderExecuteTime,
        "siteProperty": siteProperty,
        "note": note,
        "sources": sources,
      };

      // 移除 payload 中值為 null 的鍵，避免傳送不必要的空資料
      payload.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

      final response = await BaseApi.post('/Site/InsertNewSite', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 成功，回傳 null 錯誤訊息以及 'data' 物件
        return (null, decoded['data'] as Map<String, dynamic>?);
      } else {
        // 失敗，回傳後端提供的錯誤訊息
        return (decoded['message']?.toString() ?? '新增失敗，錯誤碼：${response.statusCode}', null);
      }
    } catch (e) {
      // 網路或解析錯誤
      return ('無法連線至伺服器：$e', null);
    }
  }

  /// 2. 根據團隊 UUID 取得所有工地
  static Future<List<Map<String, dynamic>>?> getSitesByTeam(String teamUUID) async {
    try {
      final response = await BaseApi.get('/Site/GetSiteByTeam/$teamUUID');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          // 確保 data 是 List<dynamic>
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}