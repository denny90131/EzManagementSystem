import 'dart:convert';
import 'package:http/http.dart' as http;

/// 自訂 API 例外處理
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): ';
}

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
    return TeamModel(
      teamUUID: json['TeamUUID'] ?? '',
      generatorUUID: json['GeneratorUUID'] ?? '',
      teamName: json['TeamName'] ?? '',
      createdDate: DateTime.parse(json['CreatedDate']),
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
      licenseKey: json['LicenseKey'] ?? '',
      subscriptionPlan: json['SubscriptionPlan'] ?? '',
      teamUUID: json['TeamUUID'] ?? '',
      licenseStatus: json['LicenseStatus'] ?? '',
      activatedAt: DateTime.parse(json['ActivatedAt']),
      expiredAt: DateTime.parse(json['ExpiredAt']),
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
      licenseKey: json['LicenseKey'] ?? '',
      teamUUID: json['TeamUUID'] ?? '',
      subscriptionPlan: json['SubscriptionPlan'] ?? '',
      licenseStatus: json['LicenseStatus'] ?? '',
      activatedAt: DateTime.parse(json['ActivatedAt']),
      expiredAt: DateTime.parse(json['ExpiredAt']),
    );
  }
}

/// Subscription API 服務層
class SubscriptionApiService {
  final String baseUrl;
  final http.Client _client;
  
  // 依據文件，這裡保留了原文件的拼字 (subscripion)
  static const String basePath = '/api/subscripion';

  SubscriptionApiService({
    required this.baseUrl, 
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _fullUrl => '';

  dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      final errorMsg = decoded['message'] ?? 'Unknown Error';
      throw ApiException(response.statusCode, errorMsg);
    }
  }

  /// 1. 建立團隊 (POST /creatTeam)
  Future<TeamModel> createTeam({
    required String generatorUUID,
    required String teamName,
  }) async {
    final url = Uri.parse('/creatTeam');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'GeneratorUUID': generatorUUID,
        'TeamName': teamName,
      }),
    );

    final decoded = _handleResponse(response);
    return TeamModel.fromJson(decoded['data']);
  }

  /// 2. 取得使用者所有團隊 (GET /GetTeams/{userUUID})
  Future<List<TeamModel>> getTeams(String userUUID) async {
    final url = Uri.parse('/GetTeams/');
    final response = await _client.get(url);

    final decoded = _handleResponse(response);
    final List<dynamic> data = decoded['data'] ?? [];
    return data.map((json) => TeamModel.fromJson(json)).toList();
  }

  /// 3. 取得團隊生效中方案 (GET /activePlan/{teamUUID})
  Future<ActivePlanModel> getActivePlan(String teamUUID) async {
    final url = Uri.parse('/activePlan/');
    final response = await _client.get(url);

    final decoded = _handleResponse(response);
    return ActivePlanModel.fromJson(
      decoded['data'],
      decoded['teamName'] ?? '',
      (decoded['remainingDays'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 4. 訂閱 / 續約 (POST /subscribe)
  Future<SubscriptionResponseModel> subscribe({
    required String teamUUID,
    required String subscriptionPlan,
    required String licenseKey,
  }) async {
    final url = Uri.parse('/subscribe');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'TeamUUID': teamUUID,
        'SubscriptionPlan': subscriptionPlan,
        'LicenseKey': licenseKey,
      }),
    );

    final decoded = _handleResponse(response);
    return SubscriptionResponseModel.fromJson(decoded['data']);
  }
}
