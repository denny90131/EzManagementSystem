import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 可以將共同的 Domain 寫在這裡，方便統一修改
  static const String baseUrl = 'http://192.168.0.99:5243/api';

  /// 共用的 POST 請求方法，只要傳入後半段的網址 (endpoint) 即可
  static Future<http.Response> _post(String endpoint, Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  /// 共用的 GET 請求方法，只要傳入後半段的網址 (endpoint) 即可
  static Future<http.Response> _get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );
  }

  /// 共用的 DELETE 請求方法
  static Future<http.Response> _delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
    );
  }

  /// 7. 邀請使用者進入團隊 (透過 Email 或手機號碼)
  static Future<(bool isSuccess, String message)> inviteToTeam(String emailOrPhone, String teamUuid) async {
    try {
      final payload = {
        "emailOrPhone": emailOrPhone,
        "teamUUID": teamUuid
      };

      // 💡 請確認您的後端 Controller 路由。如果這個 API 是在 TeamController 下，則為 /Team/add-to-team
      // 若是放在現有的 IdentityController 底下，請將路徑改為 /Identity/add-to-team
      final response = await _post('/Invite/add-to-team', payload);
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

      final response = await _post('/Invite/generate-code', payload);
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

      final response = await _post('/Invite/join-by-code', payload);
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