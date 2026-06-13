import 'dart:convert';
import 'package:http/http.dart' as http;

class BaseApi {
  // 可以將共同的 Domain 寫在這裡，方便統一修改
  
  // 內網測試
  //static const String baseUrl = 'http://192.168.0.99:5243/api'; 
  // 外網 Ngrok 測試 (請保持網址乾淨，只到 /api 為止)
  static const String baseUrl = 'https://onlooker-ocelot-unfilled.ngrok-free.dev/api';

  /// 共用的 POST 請求方法
  static Future<http.Response> post(String endpoint, Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  /// 共用的 GET 請求方法
  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );
  }

  /// 共用的 DELETE 請求方法
  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
    );
  }
}
