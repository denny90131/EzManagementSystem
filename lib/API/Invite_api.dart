import 'dart:convert';
import 'All_api.dart'; // 引入共用 API

class ApiService {

  /// 7. 邀請使用者進入團隊 (透過 Email 或手機號碼)
  static Future<(bool isSuccess, String message)> inviteToTeam(String emailOrPhone, String teamUuid) async {
    try {
      final payload = {
        "emailOrPhone": emailOrPhone,
        "teamUUID": teamUuid
      };

      // 💡 請確認您的後端 Controller 路由。如果這個 API 是在 TeamController 下，則為 /Team/add-to-team
      // 若是放在現有的 IdentityController 底下，請將路徑改為 /Identity/add-to-team
      final response = await BaseApi.post('/Invite/add-to-team', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (true, decoded['message']?.toString() ?? '成功邀請使用者加入團隊');
      } else {
        return (false, decoded['message']?.toString() ?? '邀請失敗，請稍後再試');
      }
    } catch (e) {
      return (false, '無法連線至伺服器：$e');
    }
  }

  /// 8. 產生團隊邀請碼
  static Future<String?> generateInviteCode(String teamUuid) async {
    try {
      final payload = {
        "TeamUUID": teamUuid
      };

      final response = await BaseApi.post('/Invite/generate-code', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded['inviteCode']?.toString();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 9. 透過邀請碼加入團隊
  static Future<(bool isSuccess, String message)> joinTeamByCode(String inviteCode, String memberUuid) async {
    try {
      final payload = {
        "InviteCode": inviteCode,
        "MemberUUID": memberUuid
      };

      final response = await BaseApi.post('/Invite/join-by-code', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (true, decoded['message']?.toString() ?? '成功加入團隊');
      } else {
        return (false, decoded['message']?.toString() ?? '加入失敗，請確認邀請碼是否正確或已過期');
      }
    } catch (e) {
      return (false, '無法連線至伺服器：$e');
    }
  }
}