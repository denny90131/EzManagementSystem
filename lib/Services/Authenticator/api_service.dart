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

  /// 1. 檢查資料庫連線狀態
  static Future<bool> checkConnection() async {
    try {
      final response = await _get('/Identity/check-connection');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 2. 取得所有客戶資料
  static Future<List<dynamic>?> getAllUsers() async {
    try {
      final response = await _get('/Identity/');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] ?? decoded;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 3. 取得單筆客戶資料
  static Future<Map<String, dynamic>?> getUserById(String id) async {
    try {
      final response = await _get('/Identity/$id');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] ?? decoded; // 確保能解開後端的 data 包裝
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 4. 取得客戶資料填寫進度
  static Future<Map<String, dynamic>?> getCompletionStatus(String userId) async {
    try {
      final response = await _get('/Identity/$userId/completion-status');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null; // 失敗時回傳 null
      }
    } catch (e) {
      return null;
    }
  }

  /// 4. 客戶登入 (Login)
  static Future<(String? errorMessage, Map<String, dynamic>? userData)> loginUser(String phoneNumber, String password) async {
    try {
      final payload = {
        "phoneNumber": phoneNumber,
        "password": password
      };
      final response = await _post('/Identity/login', payload);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // 登入成功，回傳 null 錯誤訊息以及 'data' 物件
        return (null, body['data'] as Map<String, dynamic>?);
      } else if (response.statusCode == 401) {
        return ('電話號碼或密碼錯誤', null);
      } else {
        return ('伺服器回應錯誤碼：${response.statusCode}', null);
      }
    } catch (e) {
      return ('無法連線至伺服器：$e', null);
    }
  }

  /// 5. 新增或更新客戶資料 (Upsert)
  /// 回傳 null 代表成功，回傳字串代表有錯誤訊息
  static Future<String?> registerUser(Map<String, dynamic> payload) async {
    try {
      final response = await _post('/Identity/upsert', payload);

      if (response.statusCode == 200) {
        return null; // 成功不回傳錯誤
      } else {
        // 嘗試解析後端回傳的詳細錯誤訊息
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['errors'] != null) {
            // 解析欄位驗證錯誤 (Validation Errors)
            Map<String, dynamic> errors = decoded['errors'];
            List<String> messages = [];
            errors.forEach((key, value) {
              if (value is List) messages.addAll(value.map((e) => e.toString()));
              else messages.add(value.toString());
            });
            return messages.join('\n'); // 將多個錯誤換行組合
          } else if (decoded['message'] != null) {
            return decoded['message']; // 一般錯誤訊息
          }
        } catch (_) {}
        
        return '錯誤碼：${response.statusCode}\n內容：${response.body}';
      }
    } catch (e) {
      return '無法連線至伺服器：$e';
    }
  }

  /// 5.5 更新客戶資料 (Upsert)
  static Future<String?> updateUser(Map<String, dynamic> payload) async {
    try {
      final response = await _post('/Identity/upsert', payload);

      if (response.statusCode == 200) {
        return null; // 成功不回傳錯誤
      } else {
        // 嘗試解析後端回傳的詳細錯誤訊息
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['errors'] != null) {
            // 解析欄位驗證錯誤 (Validation Errors)
            Map<String, dynamic> errors = decoded['errors'];
            List<String> messages = [];
            errors.forEach((key, value) {
              if (value is List) messages.addAll(value.map((e) => e.toString()));
              else messages.add(value.toString());
            });
            return messages.join('\n'); // 將多個錯誤換行組合
          } else if (decoded['message'] != null) {
            return decoded['message']; // 一般錯誤訊息
          }
        } catch (_) {}
        
        return '錯誤碼：${response.statusCode}\n內容：${response.body}';
      }
    } catch (e) {
      return '無法連線至伺服器：$e';
    }
  }

  /// 6. 刪除客戶資料
  static Future<String?> deleteUser(String id) async {
    try {
      final response = await _delete('/Identity/$id');
      if (response.statusCode == 200) return null;
      return '刪除失敗：${response.statusCode}';
    } catch (e) {
      return '無法連線：$e';
    }
  }
}