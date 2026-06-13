import 'dart:convert';
import 'All_api.dart'; // 引入共用 API

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
    final rawActivated = json['ActivatedAt'] ?? json['activatedAt'];
    final rawExpired = json['ExpiredAt'] ?? json['expiredAt'];
    
    final activatedAt = (rawActivated != null && rawActivated.toString().isNotEmpty) ? (DateTime.tryParse(rawActivated.toString()) ?? DateTime.now()) : DateTime.now();
    final expiredAt = (rawExpired != null && rawExpired.toString().isNotEmpty) ? (DateTime.tryParse(rawExpired.toString()) ?? DateTime.now()) : DateTime.now();

    // 若後端未提供 remainingDays 或抓取為 0，則利用過期日自行補算
    double actualRemainingDays = remainingDays;
    if (actualRemainingDays <= 0) {
      final diff = expiredAt.difference(DateTime.now());
      if (diff.inDays > 0) actualRemainingDays = diff.inDays.toDouble();
      else if (diff.inSeconds > 0) actualRemainingDays = 1.0; // 不足一天但未過期，至少顯示 1 天
    }
    else if (actualRemainingDays > 0 && actualRemainingDays < 1) {
      actualRemainingDays = 1.0; // 若後端直接回傳不足 1 天的小數，也保底顯示 1 天
    }

    return ActivePlanModel(
      licenseKey: (json['LicenseKey'] ?? json['licenseKey'])?.toString() ?? '',
      subscriptionPlan: (json['SubscriptionPlan'] ?? json['subscriptionPlan'])?.toString() ?? '',
      teamUUID: (json['TeamUUID'] ?? json['teamUUID'])?.toString() ?? '',
      licenseStatus: (json['LicenseStatus'] ?? json['licenseStatus'])?.toString() ?? '',
      activatedAt: activatedAt,
      expiredAt: expiredAt,
      teamName: teamName,
      remainingDays: actualRemainingDays,
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
    final rawActivated = json['ActivatedAt'] ?? json['activatedAt'];
    final rawExpired = json['ExpiredAt'] ?? json['expiredAt'];

    return SubscriptionResponseModel(
      licenseKey: (json['LicenseKey'] ?? json['licenseKey'])?.toString() ?? '',
      teamUUID: (json['TeamUUID'] ?? json['teamUUID'])?.toString() ?? '',
      subscriptionPlan: (json['SubscriptionPlan'] ?? json['subscriptionPlan'])?.toString() ?? '',
      licenseStatus: (json['LicenseStatus'] ?? json['licenseStatus'])?.toString() ?? '',
      activatedAt: (rawActivated != null && rawActivated.toString().isNotEmpty) ? (DateTime.tryParse(rawActivated.toString()) ?? DateTime.now()) : DateTime.now(),
      expiredAt: (rawExpired != null && rawExpired.toString().isNotEmpty) ? (DateTime.tryParse(rawExpired.toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }
}

/// Subscription API 服務層
class SubscriptionApiService {

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
      final response = await BaseApi.post('/Subscription/creatTeam', payload);
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
      final response = await BaseApi.get('/Subscription/GetTeams/$userUUID');
      
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
      final response = await BaseApi.get('/Subscription/activePlan/$teamUUID');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data == null) return null; // 如果沒有訂閱資料物件，直接回傳 null
        
        // 多重檢查 remainingDays 的位置 (根目錄、data物件內、大寫或小寫)
        double rDays = (decoded['remainingDays'] as num?)?.toDouble() ?? 
                       (data['remainingDays'] as num?)?.toDouble() ?? 
                       (data['RemainingDays'] as num?)?.toDouble() ?? 0.0;

        return ActivePlanModel.fromJson(
          Map<String, dynamic>.from(data),
          (decoded['teamName'] ?? decoded['TeamName'] ?? '').toString(),
          rDays,
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
      final response = await BaseApi.post('/Subscription/subscribe', payload);
      
      print('--- [Debug] 訂閱 API 狀態碼: ${response.statusCode} ---');
      print('--- [Debug] 訂閱 API 回傳值: ${response.body} ---');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return (null, SubscriptionResponseModel.fromJson(Map<String, dynamic>.from(decoded['data'] ?? {})));
      } else {
        String errorMsg = '訂閱失敗，錯誤碼：${response.statusCode}';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded['message'] != null) errorMsg = decoded['message'].toString();
        } catch (_) {
          if (response.body.isNotEmpty) errorMsg = response.body;
        }
        return (errorMsg, null);
      }
    } catch (e) {
      print('訂閱 API 發生例外錯誤: $e');
      return ('無法連線至伺服器：$e', null);
    }
  }
}
