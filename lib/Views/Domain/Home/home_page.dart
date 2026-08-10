import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // 🚀 引入 compute 所需套件
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ez_manager/Views/Domain/Home/Management_Module/Dashboard.dart'; // 引入新的儀表板模組
import 'package:ez_manager/Views/Domain/Home/Management_Module/Employee_Status_Section.dart'; // 引入新的員工狀態模組
import 'package:shared_preferences/shared_preferences.dart';
import '../../../API/Authenticator_api.dart';
import '../../../API/construction_api.dart'; // 引入工地 API
import '../../../API/Subscribe_api.dart'; // 引入訂閱 API
import '../../../API/Team_api.dart'; // 引入團隊 API
import 'Setting/Settings_Sheet.dart'; // 引入獨立的底部選單元件
import 'ConstructionSite/Add_Construction.dart'; // 引入新增工地的獨立對話框
import 'Dispatch/Dispatch_Work.dart'; // 引入派工的獨立對話框
import 'ConstructionSite/Construction_Site_Details.dart'; // 引入工地列表元件

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = '載入中...';
  String? _userPictureBase64;
  Uint8List? _userPictureBytes; // 新增：存放解析完成的大頭貼位元組，避免 build 期間重複計算卡頓
  String? _userCompany;
  String? _userPosition;
  String? _userPhone;
  bool _isProfileComplete = true; // 新增：追蹤個人資料是否完整
  Map<String, dynamic>? _fullUserData;
  List<Map<String, dynamic>> _teamMembers = []; // 新增：團隊成員名單
  List<Map<String, dynamic>> _sites = []; // 新增：工地列表
  List<Map<String, dynamic>> _filteredSites = []; // 新增：過濾後的工地列表
  final TextEditingController _searchController = TextEditingController(); // 新增：搜尋控制器
  bool _isLoading = true; // 新增：控制載入中動畫狀態
  bool _isSubscribed = false; // 新增：追蹤團隊是否已訂閱
  
  String? _selectedTeamId; // 目前選擇的團隊 ID
  List<Map<String, String>> _userTeams = [];

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _fullUserData = widget.userData;
      _userName = widget.userData!['name'] ?? '使用者';
      _userPictureBase64 = widget.userData!['picture']; // 取得大頭貼 Base64
      _userCompany = widget.userData!['company'];
      _userPosition = widget.userData!['position'];
      _userPhone = widget.userData!['phoneNumber'];
      
      // 🚀 將單張圖片解析丟到 Event Loop 中延遲執行，避免阻塞 initState 造成轉場掉幀
      if (_userPictureBase64 != null && _userPictureBase64!.isNotEmpty) {
        Future(() {
          try {
            final bytes = base64Decode(_userPictureBase64!.split(',').last.replaceAll(RegExp(r'\s+'), ''));
            if (mounted) setState(() => _userPictureBytes = bytes);
          } catch (_) {}
        });
      }
      
      // 讀取登入時一併抓好的資料完整度狀態
      if (widget.userData!['isProfileComplete'] != null) {
        _isProfileComplete = widget.userData!['isProfileComplete'];
      }
      _fetchData(fetchUser: false); // 已有登入傳來的資料，初次載入省略請求個人 API
    } else {
      _fetchData(fetchUser: true); // 沒有初始資料，必須抓取
    }

    // 監聽搜尋框的輸入變化
    _searchController.addListener(_filterSites);
  }

  // 根據搜尋框內容過濾工地列表
  void _filterSites() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredSites = List<Map<String, dynamic>>.from(_sites);
      } else {
        _filteredSites = _sites.where((site) {
          final siteName = (site['siteName'] ?? '').toString().toLowerCase();
          final siteAddress = (site['siteAddress'] ?? '').toString().toLowerCase();
          final siteOwner = (site['siteOwner'] ?? '').toString().toLowerCase();
          final siteClient = (site['siteClient'] ?? '').toString().toLowerCase();
          return siteName.contains(query) || 
                siteAddress.contains(query) || 
                siteOwner.contains(query) ||
                siteClient.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSites);
    _searchController.dispose();
    super.dispose();
  }

  // 新增參數 fetchUser，用來控制是否需要呼叫 User 相關的 API
  Future<void> _fetchData({bool fetchUser = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final activeTeamId = prefs.getString('active_team_uuid');
      debugPrint('[_fetchData] Active Team ID from SharedPreferences: $activeTeamId');
      
      // 1. 準備所有 API 請求 (此時不使用 await，讓它們不阻塞)
      final hasTeam = activeTeamId != null && activeTeamId.isNotEmpty;
      final membersFuture = hasTeam ? TeamApiService.getMemberTeam(activeTeamId) : Future.value(null);
      final sitesFuture = hasTeam ? ConstructionApiService.getSitesByTeam(activeTeamId) : Future.value(null); // 獲取工地列表
      final planFuture = hasTeam ? SubscriptionApiService.getActivePlan(activeTeamId) : Future.value(null);
      
      final shouldFetchUser = userId != null && fetchUser; // 根據參數決定是否發送使用者 API
      final userFuture = shouldFetchUser ? ApiService.getUserById(userId) : Future.value(null);
      final statusFuture = shouldFetchUser ? ApiService.getCompletionStatus(userId) : Future.value(null);
      
      final teamsFuture = userId != null ? SubscriptionApiService.getTeams(userId) : Future.value(null);

      // 2. 使用 Future.wait 平行發起所有請求 (大幅減少首頁轉圈圈的時間)
      final results = await Future.wait([
        membersFuture,
        sitesFuture,
        planFuture,
        userFuture,
        statusFuture,
        teamsFuture, // 🚀 將團隊列表請求加入併發陣列
      ]);

      if (!mounted) return;

      final members = results[0];
      final sites = results[1];
      final activePlan = results[2];
      final userData = results[3];
      debugPrint('[_fetchData] Raw sites data from API: $sites');
      final status = results[4];
      final teamsData = results[5]; // 取出團隊清單資料

      // 🚀 將非同步的 await 移出 setState 之外
      // 等待 compute 在背景把成員名單與 Base64 圖片都解析完畢
      List<Map<String, dynamic>> parsedMembers = [];
      if (hasTeam && members is List) { // 確保 members 是 List 且有團隊時才執行
        parsedMembers = await compute(_parseTeamMembersInBackground, members);
      }
      if (!mounted) return;

      setState(() {
        // 🚀 處理剛抓回來的團隊列表資料
        if (teamsData != null) {
          try {
            final teamModels = teamsData as List<TeamModel>;
            _userTeams = teamModels.map<Map<String, String>>((t) => {
              'id': t.teamUUID,
              'name': t.teamName.isNotEmpty ? t.teamName : '未命名團隊',
            }).where((t) => t['id']!.isNotEmpty).toList();
          } catch (e) {
            debugPrint('解析團隊列表發生錯誤: $e');
          }
        }

        // 防呆機制移到這裡：等真正的團隊資料解析完後，如果 activeTeamId 還是不在裡面才補上預設值
        if (activeTeamId != null && activeTeamId.isNotEmpty && !_userTeams.any((t) => t['id'] == activeTeamId)) {
          _userTeams.add({'id': activeTeamId, 'name': '目前團隊'});
        }

        _selectedTeamId = activeTeamId?.isEmpty == true ? null : activeTeamId;
        
        // 如果一開始未選擇過團隊但清單有資料，自動選中第一筆並抓取團隊資料
        if (_selectedTeamId == null && _userTeams.isNotEmpty) {
          _selectedTeamId = _userTeams.first['id'];
          // 這裡不能直接 setState，因為接下來的 await 會導致錯誤。
          // 我們在 setState 外處理異步操作，然後重新觸發資料抓取。
        }

      });

      if (activeTeamId == null && _userTeams.isNotEmpty) {
        debugPrint('[_fetchData] No active team selected, setting to first team: ${_userTeams.first['id']}');
        await prefs.setString('active_team_uuid', _userTeams.first['id']!);
        _fetchData(fetchUser: false);
        return; // 終止當次執行，等待下一次完整的 _fetchData
      }

      setState(() {
        // ===== 處理團隊成員資料 =====
        if (hasTeam) {
          _isSubscribed = activePlan != null && (activePlan as dynamic).remainingDays > 0;
          _teamMembers = parsedMembers; // 直接賦予已在背景運算完成的資料
          // 檢查 sites 是否為 List 型別，避免型別轉換錯誤ß
          debugPrint('[_fetchData] Processing sites data. Is sites a List? ${sites is List}');
          if (sites != null && sites is List) {
            _sites = List<Map<String, dynamic>>.from(sites);
            _filteredSites = _sites; // 初始狀態下，過濾列表等於完整列表
            _filterSites(); // 👈 強制重新執行過濾邏輯以同步畫面
          } else {
            _sites = [];
            debugPrint('[_fetchData] Sites data is null or not a List. _sites set to empty.');
          }
        } else {
          _sites = [];
          _teamMembers = [];
          _isSubscribed = false;
        }
        debugPrint('[_fetchData] Number of sites after processing: ${_sites.length}');

        // ===== 處理使用者資料 =====
        if (shouldFetchUser) {
          if (userData != null && (userData as Map)['name'] != null) {
            _fullUserData = userData as Map<String, dynamic>;
            _userName = userData['name'];
            _userPictureBase64 = userData['picture'];
            _userCompany = userData['company'];
            _userPosition = userData['position'];
            _userPhone = userData['phoneNumber'];
            
            if (_userPictureBase64 != null && _userPictureBase64!.isNotEmpty) {
              Future(() {
                try {
                  final bytes = base64Decode(_userPictureBase64!.split(',').last.replaceAll(RegExp(r'\s+'), ''));
                  if (mounted) setState(() => _userPictureBytes = bytes);
                } catch (_) {}
              });
            }
          } else if (_userName == '載入中...') {
            _userName = '使用者';
          }
          
          if (status != null) {
            _isProfileComplete = (status as Map)['isComplete'];
          }
        } else if (userId == null && _userName == '載入中...') {
          _userName = '訪客';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_userName == '載入中...') _userName = '無法載入';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // 無論成功失敗，結束載入狀態
    }
  }

  // 顯示設定選單 (點擊姓名大頭貼時觸發)
  void _showSettings(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: const Color(0xFF1A2232), // 卡片底色
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext sheetContext) {
        return SettingsBottomSheet(
          userName: _userName,
          userPictureBase64: _userPictureBase64,
          userCompany: _userCompany,
          userPosition: _userPosition,
          userPhone: _userPhone,
          isProfileComplete: _isProfileComplete,
          fullUserData: _fullUserData,
          parentContext: parentContext,
          onDataUpdated: () => _fetchData(fetchUser: true), // 從編輯頁面返回時，強制重新抓取最新的 User API
        );
      },
    );
  }

  // 案件詳細資訊列 (供員工詳情彈窗共用)
  Widget _buildCaseInfoRow(IconData icon, String text, [Color? iconColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? const Color(0xFF8A94A6)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF8A94A6), height: 1.4, fontSize: 14)),
        ),
      ],
    );
  }

  // 顯示員工詳細資訊的底部彈出視窗
  void _showEmployeeDetails(BuildContext context, Map<String, dynamic> member, bool isWorking) {
    String avatarChar = member['name'].toString().isNotEmpty ? member['name'].toString().substring(0, 1) : '?';
    final Uint8List? pictureBytes = member['pictureBytes'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2232), // 深色卡片背景
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true, // 允許內容超出預設高度
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 頂部簡介
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isWorking ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      backgroundImage: pictureBytes != null ? MemoryImage(pictureBytes) : null,
                      child: pictureBytes == null ? Text(avatarChar, style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 20)) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(isWorking ? '狀態：施工中 (中山區案件)' : '狀態：待命中', style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontSize: 14)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF8A94A6)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Colors.white12),
                
                // 聯絡方式
                const Text('聯絡方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                _buildCaseInfoRow(Icons.phone_outlined, member['phone'], const Color(0xFFE5BA73)),
                const SizedBox(height: 12),
                _buildCaseInfoRow(
                  Icons.contact_emergency_outlined, 
                  '緊急聯絡人: ${member['iceName']} ${member['iceRelation'].isNotEmpty ? '(${member['iceRelation']})' : ''}\n${member['icePhone']}', 
                  const Color(0xFFE5BA73)
                ),
                
                if (member['teamNote'] != null && member['teamNote'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCaseInfoRow(Icons.note_alt_outlined, '團隊備註: ${member['teamNote']}', const Color(0xFFE5BA73)),
                ],
                if (member['personalNote'] != null && member['personalNote'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildCaseInfoRow(Icons.assignment_ind_outlined, '個人備註: ${member['personalNote']}', const Color(0xFF8A94A6)),
                ],
                
                const SizedBox(height: 24),
                
                // 派工紀錄
                const Text('近期派工紀錄', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
                  itemBuilder: (context, rIndex) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_edu, color: Color(0xFF8A94A6)),
                      title: Text('案件：${['大安區豪宅裝潢', '信義區百貨管線', '中山區辦公大樓'][rIndex]}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text('日期：2023-11-${20 - rIndex}', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                      trailing: const Text('已完成', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 動態計算當前出勤與空班人數
    final workingCount = _teamMembers.where((m) => m['isWorking'] == true).length;
    final idleCount = _teamMembers.length - workingCount;

    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 頁面深色背景
      body: Column(
        children: [
          // 固定最上方的欄位 (使用者資訊與按鈕)
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 16),
            color: const Color(0xFF121824), // 加上背景色避免滾動內容透視
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showSettings(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: _userPictureBytes != null
                                    ? MemoryImage(_userPictureBytes!) : null,
                                child: _userPictureBytes == null
                                    ? const Icon(Icons.person, color: Colors.white, size: 28)
                                    : null,
                              ),
                              // 讓首頁的大頭貼也能直接顯示紅色驚嘆號提示
                              if (!_isProfileComplete)
                                const Positioned(
                                  right: -2,
                                  bottom: 0,
                                  child: Icon(Icons.error, color: Colors.redAccent, size: 18),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi, $_userName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日 星期${['一', '二', '三', '四', '五', '六', '日'][DateTime.now().weekday - 1]}',
                                style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 團隊下拉選單 (放置在頭貼與名字下方)
                      IntrinsicWidth(
                        child: PopupMenuButton<String>(
                          initialValue: _selectedTeamId,
                          offset: const Offset(0, 36), // 強制往下偏移，實現往下展開效果
                          color: const Color(0xFF1E2532), // 深色選單卡片
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: const Color(0xFFE5BA73).withOpacity(0.3)),
                          ),
                          onSelected: (String? newValue) async {
                            if (newValue != null && newValue != _selectedTeamId) {
                              setState(() {
                                _selectedTeamId = newValue;
                                _isLoading = true; // 切換時顯示載入中動畫
                              });
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('active_team_uuid', newValue);
                              _fetchData(fetchUser: false); // 背景重新抓取該團隊資料
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return _userTeams.map((team) {
                              final isSelected = team['id'] == _selectedTeamId;
                              return PopupMenuItem<String>(
                                value: team['id'],
                                child: Text(
                                  team['name']!,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFE5BA73) : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          child: Container(
                            height: 32,
                            constraints: const BoxConstraints(minWidth: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2232),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedTeamId != null 
                                      ? (_userTeams.firstWhere((t) => t['id'] == _selectedTeamId, orElse: () => {'name': '選擇團隊'})['name'] ?? '選擇團隊') 
                                      : '選擇團隊',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFFE5BA73), fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.keyboard_arrow_down, color: Color(0xFFE5BA73), size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_isSubscribed) ...[
                      Tooltip(
                        message: '新增工地',
                        child: ElevatedButton( // 呼叫獨立的靜態方法
                          onPressed: () async {
                            final result = await showDialog<bool>(context: context, builder: (ctx) => const AddConstructionDialog());
                            if (result == true) {
                              _fetchData(fetchUser: false); // 如果新增成功，則重新抓取資料
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2232), // 深色底搭配金邊
                            side: const BorderSide(color: Color(0xFFE5BA73)),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(36, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Icon(Icons.add, size: 20, color: Color(0xFFE5BA73)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => DispatchDialog.show(
                          context,
                              members: _teamMembers.map((m) { // 👈 移除 =>，改用標準大括號區塊
                          debugPrint('[DispatchDialog] Member data before sending: $m');
                          return {
                            'id': m['memberUUID']?.toString() ?? '', 
                            'name': m['name']?.toString() ?? '', 
                          };
                        }).toList(),
                          sites: _sites.map((s) => {
                            'id': s['siteUUID']?.toString() ?? '', // 安全地轉換為 String，避免 null
                            'name': s['siteName']?.toString() ?? '', // 安全地轉換為 String，避免 null
                          }).toList(),
                        ),
                        icon: const Icon(Icons.assignment_ind_outlined, size: 16, color: Colors.black),
                        label: const Text('派工', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5BA73), // 金色
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ],
                )
              ],
            ),
          ),
          
          // 滾動內容區 (儀表板、蜂巢圖、清單等)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchData(fetchUser: true), // 使用者下拉更新時，強制重新抓取所有的 API
              color: const Color(0xFFE5BA73), // 金色轉圈圈
              backgroundColor: const Color(0xFF1A2232),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // 確保內容過少時依然可下拉
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardSection( // 引入新的儀表板模組
                      teamMembers: _teamMembers,
                      isLoading: _isLoading,
                    ),
                    // 員工狀態與工地列表
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: EmployeeStatusSection(
                        workingCount: workingCount,
                        teamMembers: _teamMembers,
                        isLoading: _isLoading,
                        onShowEmployeeDetails: _showEmployeeDetails,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ConstructionSiteList(
                        sites: _sites,
                        filteredSites: _filteredSites,
                        searchController: _searchController,
                        isLoading: _isLoading,
                      ),
                    ),
          ],
        ),
      ),
    ),
  ),
      ],
    ),
  );
}
}

// 🚀 放在檔案最底部的頂層函數，專門用來在背景 Isolate 處理耗時的 List 與 Base64 轉換
List<Map<String, dynamic>> _parseTeamMembersInBackground(List<dynamic> members) {
  return members.map<Map<String, dynamic>>((m) {
    
    final profile = m['profile'] ?? {};
    final teamInfo = m['teamInfo'] ?? m['TeamInfo'] ?? {};
    
    Uint8List? picBytes;
    final picStr = profile['picture'] ?? profile['Picture'];
    if (picStr != null && picStr.toString().isNotEmpty) {
      try { picBytes = base64Decode(picStr.toString().split(',').last.replaceAll(RegExp(r'\s+'), '')); } catch (_) {}
    }
    
    final String extractedMemberUUID = teamInfo['memberUUID'] ?? teamInfo['MemberUUID'] ?? m['MemberUUID'] ?? m['memberUUID'] ?? ''; // 🚀 優先從 teamInfo 中提取 memberUUID
    debugPrint('[_parseTeamMembersInBackground] Extracted memberUUID: $extractedMemberUUID'); // 🚀 檢查提取到的 memberUUID
    return {
      'memberUUID': extractedMemberUUID, // 確保 MemberUUID 被解析並加入，並使用小寫鍵名
      'name': profile['name'] ?? profile['Name'] ?? '未命名',
      'picture': profile['picture'] ?? profile['Picture'],
      'pictureBytes': picBytes, // 存入已解析的圖片
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