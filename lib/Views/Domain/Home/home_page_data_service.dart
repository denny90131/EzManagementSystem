import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ez_manager/API/Authenticator_api.dart';
import 'package:ez_manager/API/construction_api.dart';
import 'package:ez_manager/API/Subscribe_api.dart';
import 'package:ez_manager/API/Team_api.dart';
import 'dart:convert';

/// 封裝從服務獲取的所有首頁資料。
class HomePageData {
  final Map<String, dynamic>? fullUserData;
  final bool isProfileComplete;
  final List<Map<String, dynamic>> teamMembers;
  final List<Map<String, dynamic>> sites;
  final bool isSubscribed;
  final String? selectedTeamId;
  final List<Map<String, String>> userTeams;
  final bool needsRefetch;

  HomePageData({
    this.fullUserData,
    required this.isProfileComplete,
    required this.teamMembers,
    required this.sites,
    required this.isSubscribed,
    this.selectedTeamId,
    required this.userTeams,
    this.needsRefetch = false,
  });
}

/// 專門處理首頁資料獲取的服務類別。
class HomePageDataService {
  /// 在背景 Isolate 中解析團隊成員列表，避免 UI 執行緒卡頓。
  static List<Map<String, dynamic>> _parseTeamMembersInBackground(List<dynamic> members) {
    return members.map<Map<String, dynamic>>((m) {
      final profile = m['profile'] ?? {};
      final teamInfo = m['teamInfo'] ?? m['TeamInfo'] ?? {};

      Uint8List? picBytes;
      final picStr = profile['picture'] ?? profile['Picture'];
      if (picStr != null && picStr.toString().isNotEmpty) {
        try {
          picBytes = base64Decode(picStr.toString().split(',').last.replaceAll(RegExp(r'\s+'), ''));
        } catch (_) {}
      }

      final String extractedMemberUUID = teamInfo['memberUUID'] ?? teamInfo['MemberUUID'] ?? m['MemberUUID'] ?? m['memberUUID'] ?? '';
      return {
        'memberUUID': extractedMemberUUID,
        'name': profile['name'] ?? profile['Name'] ?? '未命名',
        'picture': profile['picture'] ?? profile['Picture'],
        'pictureBytes': picBytes,
        'phone': profile['phoneNumber'] ?? profile['PhoneNumber'] ?? '無',
        'iceName': profile['iceName'] ?? profile['ICEName'] ?? '無',
        'icePhone': profile['icePhoneNumber'] ?? profile['ICEPhoneNumber'] ?? '無',
        'iceRelation': profile['iceRelation'] ?? profile['ICERelation'] ?? '',
        'teamNote': teamInfo['note'] ?? teamInfo['Note'] ?? '',
        'personalNote': profile['note'] ?? profile['Note'] ?? '',
        'isWorking': false,
      };
    }).toList();
  }

  /// 獲取首頁所需的所有資料。
  ///
  /// [fetchUser] 控制是否需要重新獲取使用者個人資訊。
  /// [initialUserData] 登入或註冊後傳入的初始使用者資料。
  static Future<HomePageData> fetchHomePageData({
    bool fetchUser = true,
    Map<String, dynamic>? initialUserData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    String? activeTeamId = prefs.getString('active_team_uuid');

    // 1. 準備所有 API 請求
    final hasTeam = activeTeamId != null && activeTeamId.isNotEmpty;
    final membersFuture = hasTeam ? TeamApiService.getMemberTeam(activeTeamId) : Future.value(null);
    final sitesFuture = hasTeam ? ConstructionApiService.getSitesByTeam(activeTeamId) : Future.value(null);
    final planFuture = hasTeam ? SubscriptionApiService.getActivePlan(activeTeamId) : Future.value(null);

    final shouldFetchUser = userId != null && fetchUser;
    final userFuture = shouldFetchUser ? ApiService.getUserById(userId) : Future.value(null);
    final statusFuture = shouldFetchUser ? ApiService.getCompletionStatus(userId) : Future.value(null);

    final teamsFuture = userId != null ? SubscriptionApiService.getTeams(userId) : Future.value(null);

    // 2. 平行發起所有請求
    final results = await Future.wait([
      membersFuture,
      sitesFuture,
      planFuture,
      userFuture,
      statusFuture,
      teamsFuture,
    ]);

    final members = results[0];
    final sitesData = results[1];
    final activePlan = results[2];
    final userDataFromApi = results[3];
    final status = results[4];
    final teamsData = results[5];

    // 3. 處理團隊列表
    List<Map<String, String>> userTeams = [];
    if (teamsData != null) {
      final teamModels = teamsData as List<TeamModel>;
      userTeams = teamModels
          .map<Map<String, String>>((t) => {
                'id': t.teamUUID,
                'name': t.teamName.isNotEmpty ? t.teamName : '未命名團隊',
              })
          .where((t) => t['id']!.isNotEmpty)
          .toList();
    }

    // 4. 處理並返回資料模型
    if (activeTeamId == null && userTeams.isNotEmpty) {
      activeTeamId = userTeams.first['id'];
      await prefs.setString('active_team_uuid', activeTeamId!);
      return HomePageData(
        isProfileComplete: true,
        teamMembers: [],
        sites: [],
        isSubscribed: false,
        userTeams: userTeams,
        needsRefetch: true, // 標記需要重新抓取
      );
    }

    List<Map<String, dynamic>> parsedMembers = [];
    if (hasTeam && members is List) {
      parsedMembers = await compute(_parseTeamMembersInBackground, members);
    }

    Map<String, dynamic>? fullUserData = initialUserData;
    if (shouldFetchUser && userDataFromApi != null) {
      fullUserData = userDataFromApi as Map<String, dynamic>;
    }

    bool isProfileComplete = initialUserData?['isProfileComplete'] ?? true;
    if (status != null) {
      isProfileComplete = (status as Map)['isComplete'];
    }

    return HomePageData(
      fullUserData: fullUserData,
      isProfileComplete: isProfileComplete,
      teamMembers: parsedMembers,
      sites: sitesData != null && sitesData is List ? List<Map<String, dynamic>>.from(sitesData) : [],
      isSubscribed: activePlan != null && (activePlan as dynamic).remainingDays > 0,
      selectedTeamId: activeTeamId,
      userTeams: userTeams,
    );
  }
}