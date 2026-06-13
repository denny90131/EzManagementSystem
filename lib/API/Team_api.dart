import 'dart:convert';
import 'All_api.dart'; // 引入共用 API

class TeamApiService {

  /// 1. 以團隊 UUID 查詢各團員詳細資料
  static Future<List<dynamic>?> getMemberTeam(String teamUUID) async {
    try {
      final response = await BaseApi.get('/Team/GetMemberTeam?teamUUID=$teamUUID');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // 處理後端可能包裝在 data 屬性內的狀況
        if (decoded is List) return decoded;
        if (decoded is Map && decoded.containsKey('data')) return decoded['data'];
        return []; // 成功但無資料
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 2. 以團員 UUID 查詢所屬團隊
  static Future<List<dynamic>?> getTeamByMember(String memberUUID) async {
    try {
      final response = await BaseApi.get('/Team/GetTeamByMember?memberUUID=$memberUUID');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded.containsKey('data')) return decoded['data'];
        return [];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 3. 編輯團隊成員設定（職務權限、薪資）
  static Future<(bool isSuccess, String message)> editMemberFromTeam({
    required String teamUuid,
    required String executorMemberUuid,
    required String targetMemberUuid,
    int? permissionCode,
    num? salary,
    String? note
  }) async {
    try {
      final payload = {
        "TeamUUID": teamUuid,
        "ExecutorMemberUUID": executorMemberUuid,
        "TargetMemberUUID": targetMemberUuid,
        if (permissionCode != null) "PermissionCode": permissionCode,
        if (salary != null) "Salary": salary,
        if (note != null) "Note": note,
      };

      final response = await BaseApi.post('/Team/EditMemberFromTeam', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (true, decoded['message']?.toString() ?? '團隊成員資料更新成功');
      } else {
        return (false, decoded['message']?.toString() ?? '更新失敗，錯誤碼：${response.statusCode}');
      }
    } catch (e) {
      return (false, '無法連線至伺服器：$e');
    }
  }

  /// 4. 刪除（踢出）團隊成員
  static Future<(bool isSuccess, String message)> deleteMemberFromTeam({
    required String teamUuid,
    required String executorMemberUuid,
    required String targetMemberUuid,
  }) async {
    try {
      final payload = {
        "TeamUUID": teamUuid,
        "ExecutorMemberUUID": executorMemberUuid,
        "TargetMemberUUID": targetMemberUuid,
      };

      final response = await BaseApi.post('/Team/DeleteMemberFromTeam', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (true, decoded['message']?.toString() ?? '已成功將該成員移出團隊');
      } else {
        return (false, decoded['message']?.toString() ?? '移除失敗，錯誤碼：${response.statusCode}');
      }
    } catch (e) {
      return (false, '無法連線至伺服器：$e');
    }
  }
}
