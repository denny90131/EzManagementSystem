import 'dart:convert';
import 'package:http/http.dart' as http;

/// 模型：團隊資訊
class TeamModel {
  final String teamUUID;
  final String generatorUUID;
  final String teamName;
  final DateTime createdDate;

  TeamModel({
    required this.teamUUID,
    required this.generatorUUID,
    required this.teamName,
    required this.createdDate,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['CreatedDate'] ?? json['createdDate'];
    return TeamModel(
      teamUUID: (json['TeamUUID'] ?? json['teamUUID'])?.toString() ?? '',
      generatorUUID: (json['GeneratorUUID'] ?? json['generatorUUID'])?.toString() ?? '',
      teamName: (json['TeamName'] ?? json['teamName'])?.toString() ?? '',
      createdDate: (rawDate != null && rawDate.toString().isNotEmpty) ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

/// 模型：生效中的訂閱方案資訊
class ActivePlanModel {
  final String licenseKey;
  final String subscriptionPlan;
  final String teamUUID;
  final String licenseStatus;
  final DateTime activatedAt;
  final DateTime expiredAt;
  final String teamName;
  final double remainingDays;

  ActivePlanModel({
    required this.licenseKey,
    required this.subscriptionPlan,
    required this.teamUUID,
    required this.licenseStatus,
    required this.activatedAt,
    required this.expiredAt,
    required this.teamName,
    required this.remainingDays,
  });

  factory ActivePlanModel.fromJson(Map<String, dynamic> json, String teamName, double remainingDays) {
    return ActivePlanModel(
      licenseKey: json['LicenseKey']?.toString() ?? '',
      subscriptionPlan: json['SubscriptionPlan']?.toString() ?? '',
      teamUUID: json['TeamUUID']?.toString() ?? '',
      licenseStatus: json['LicenseStatus']?.toString() ?? '',
      activatedAt: (json['ActivatedAt'] != null && json['ActivatedAt'].toString().isNotEmpty) ? (DateTime.tryParse(json['ActivatedAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      expiredAt: (json['ExpiredAt'] != null && json['ExpiredAt'].toString().isNotEmpty) ? (DateTime.tryParse(json['ExpiredAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      teamName: teamName,
      remainingDays: remainingDays,
    );
  }
}

/// 模型：訂閱成功回應資訊
class SubscriptionResponseModel {
  final String licenseKey;
  final String teamUUID;
  final String subscriptionPlan;
  final String licenseStatus;
  final DateTime activatedAt;
  final DateTime expiredAt;

  SubscriptionResponseModel({
    required this.licenseKey,
    required this.teamUUID,
    required this.subscriptionPlan,
    required this.licenseStatus,
    required this.activatedAt,
    required this.expiredAt,
  });

  factory SubscriptionResponseModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponseModel(
      licenseKey: json['LicenseKey']?.toString() ?? '',
      teamUUID: json['TeamUUID']?.toString() ?? '',
      subscriptionPlan: json['SubscriptionPlan']?.toString() ?? '',
      licenseStatus: json['LicenseStatus']?.toString() ?? '',
      activatedAt: (json['ActivatedAt'] != null && json['ActivatedAt'].toString().isNotEmpty) ? (DateTime.tryParse(json['ActivatedAt'].toString()) ?? DateTime.now()) : DateTime.now(),
      expiredAt: (json['ExpiredAt'] != null && json['ExpiredAt'].toString().isNotEmpty) ? (DateTime.tryParse(json['ExpiredAt'].toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

/// Subscription API 服務層
class SubscriptionApiService {
  // 可以將共同的 Domain 寫在這裡，方便統一修改
  static const String baseUrl = 'http://192.168.0.99:5243/api/subscripion';

  /// 共用的 POST 請求方法
  static Future<http.Response> _post(String endpoint, Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );
  }

  /// 共用的 GET 請求方法
  static Future<http.Response> _get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );
  }

  /// 1. 建立團隊 (POST /creatTeam)
  static Future<(String? errorMessage, TeamModel? data)> createTeam({
    required String generatorUUID,
    required String teamName,
  }) async {
    try {
      final payload = {
        'GeneratorUUID': generatorUUID,
        'TeamName': teamName,
      };
      final response = await _post('/creatTeam', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (null, TeamModel.fromJson(Map<String, dynamic>.from(decoded['data'])));
      } else {
        return (decoded['message']?.toString() ?? '建立失敗，錯誤碼：${response.statusCode}', null);
      }
    } catch (e) {
      return ('無法連線至伺服器：$e', null);
    }
  }

  /// 2. 取得使用者所有團隊 (GET /GetTeams/{userUUID})
  static Future<List<TeamModel>?> getTeams(String userUUID) async {
    try {
      final response = await _get('/GetTeams/$userUUID');
      
      print('--- [Debug] 取得團隊 API 狀態碼: ${response.statusCode} ---');
      print('--- [Debug] 取得團隊 API 回傳值: ${response.body} ---');
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        List<dynamic> data = [];
        if (decoded is Map && decoded.containsKey('data')) {
          var rawData = decoded['data'];
          if (rawData is String) try { rawData = jsonDecode(rawData); } catch(_) {} // 防呆：後端如果不小心包成了字串
          if (rawData is List) data = rawData;
        } else if (decoded is List) {
          data = decoded;
        }
        
        return data.map((json) => TeamModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return null;
    } catch (e) {
      print('取得團隊列表 JSON 解析失敗: $e');
      return null;
    }
  }

  /// 3. 取得團隊生效中方案 (GET /activePlan/{teamUUID})
  static Future<ActivePlanModel?> getActivePlan(String teamUUID) async {
    try {
      final response = await _get('/activePlan/$teamUUID');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return ActivePlanModel.fromJson(
          Map<String, dynamic>.from(decoded['data'] ?? {}),
          decoded['teamName'] ?? '',
          (decoded['remainingDays'] as num?)?.toDouble() ?? 0.0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 4. 訂閱 / 續約 (POST /subscribe)
  static Future<(String? errorMessage, SubscriptionResponseModel? data)> subscribe({
    required String teamUUID,
    required String subscriptionPlan,
    required String licenseKey,
  }) async {
    try {
      final payload = {
        'TeamUUID': teamUUID,
        'SubscriptionPlan': subscriptionPlan,
        'LicenseKey': licenseKey,
      };
      final response = await _post('/subscribe', payload);
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (null, SubscriptionResponseModel.fromJson(Map<String, dynamic>.from(decoded['data'])));
      } else {
        return (decoded['message']?.toString() ?? '訂閱失敗，錯誤碼：${response.statusCode}', null);
      }
    } catch (e) {
      return ('無法連線至伺服器：$e', null);
    }
  }
}
