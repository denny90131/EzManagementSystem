import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../API/Authenticator_api.dart';
import '../../../API/Subscribe_api.dart'; // 引入訂閱 API
import '../../../API/Team_api.dart'; // 引入團隊 API
import 'Setting/settings_sheet.dart'; // 引入獨立的底部選單元件
import 'ConstructionSite/add_construction.dart'; // 引入新增工地的獨立對話框
import 'ConstructionSite/details_construction.dart'; // 引入工地詳情頁面
import 'Dispatch/dispatch_work.dart'; // 引入派工的獨立對話框

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomePage({super.key, this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _userName = '載入中...';
  String? _userPictureBase64;
  String? _userCompany;
  String? _userPosition;
  String? _userPhone;
  bool _isProfileComplete = true; // 新增：追蹤個人資料是否完整
  Map<String, dynamic>? _fullUserData;
  List<Map<String, dynamic>> _teamMembers = []; // 新增：團隊成員名單
  bool _isLoading = true; // 新增：控制載入中動畫狀態
  bool _isSubscribed = false; // 新增：追蹤團隊是否已訂閱

  late AnimationController _animationController;
  late Animation<double> _animation;

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
      
      // 讀取登入時一併抓好的資料完整度狀態
      if (widget.userData!['isProfileComplete'] != null) {
        _isProfileComplete = widget.userData!['isProfileComplete'];
      }
    }
    
    // 無論有無傳入初始資料，都在背景執行一次以取得最新的「資料填寫進度狀態 (_isProfileComplete)」
    _fetchData(); 

    // 初始化儀表板動畫 (預設 0%，待 API 抓回資料後再動態計算目標進度)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 播放時間 1.5 秒
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      // ===== 新增：取得團隊成員資料 =====
      final activeTeamId = prefs.getString('active_team_uuid');
      if (activeTeamId != null && activeTeamId.isNotEmpty) {
        final members = await TeamApiService.getMemberTeam(activeTeamId);
        
        // 查詢當前團隊的訂閱狀態
        final activePlan = await SubscriptionApiService.getActivePlan(activeTeamId);
        final isSub = activePlan != null && activePlan.remainingDays > 0;
        
        if (mounted) {
          setState(() {
            _isSubscribed = isSub; // 記錄訂閱狀態
            if (members != null) {
              _teamMembers = members.map<Map<String, dynamic>>((m) {
                final profile = m['profile'] ?? {};
                final teamInfo = m['teamInfo'] ?? m['TeamInfo'] ?? {};
                return {
                  'name': profile['name'] ?? profile['Name'] ?? '未命名',
                  'picture': profile['picture'] ?? profile['Picture'],
                  'phone': profile['phoneNumber'] ?? profile['PhoneNumber'] ?? '無',
                  'iceName': profile['iceName'] ?? profile['ICEName'] ?? '無',
                  'icePhone': profile['icePhoneNumber'] ?? profile['ICEPhoneNumber'] ?? '無',
                  'iceRelation': profile['iceRelation'] ?? profile['ICERelation'] ?? '',
                  // 分開儲存團隊備註與個人備註
                  'teamNote': teamInfo['note'] ?? teamInfo['Note'] ?? '', // 團隊專屬備註
                  'personalNote': profile['note'] ?? profile['Note'] ?? '', // 個人基本資料備註
                  'isWorking': false, // TODO: 未來串接真實派工狀態後替換
                };
              }).toList();
            } else {
              _teamMembers = [];
            }
            _updateAttendanceAnimation(); // 資料載入完畢，更新出勤率動畫
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _teamMembers = [];
            _isSubscribed = false;
            _updateAttendanceAnimation();
          });
        }
      }
      // ==============================

      if (userId != null) {
        final userData = await ApiService.getUserById(userId);
        if (userData != null && userData['name'] != null) {
          if (mounted) setState(() {
            _fullUserData = userData;
            _userName = userData['name'];
            _userPictureBase64 = userData['picture']; // 取得大頭貼 Base64
            _userCompany = userData['company'];
            _userPosition = userData['position'];
            _userPhone = userData['phoneNumber'];
          });
          // 檢查資料填寫完整度
          final status = await ApiService.getCompletionStatus(userId);
          if (status != null && mounted) {
            setState(() => _isProfileComplete = status['isComplete']);
          }
        } else {
          if (mounted) setState(() => _userName = '使用者');
        }
      } else {
        if (mounted) setState(() => _userName = '訪客');
      }
    } catch (e) {
      if (mounted) setState(() => _userName = '無法載入');
    } finally {
      if (mounted) setState(() => _isLoading = false); // 無論成功失敗，結束載入狀態
    }
  }

  // 動態更新出勤率動畫
  void _updateAttendanceAnimation() {
    final workingCount = _teamMembers.where((m) => m['isWorking'] == true).length;
    final targetRatio = _teamMembers.isEmpty ? 0.0 : (workingCount / _teamMembers.length);
    
    _animation = Tween<double>(begin: 0.0, end: targetRatio).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward(from: 0.0); // 觸發動畫
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
          onDataUpdated: _fetchData, // 傳入重新抓取資料的函式，當從編輯頁面返回時會觸發更新大頭貼
        );
      },
    );
  }

  // 建立四個數據框的方法 (蜂巢六角形)
  Widget _buildHoneycombStat(String title, String count, Color color) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0), // 統一間距以確保蜂巢完美對齊
        child: CustomPaint(
          painter: _HoneycombPainter(
            backgroundColor: const Color(0xFF1A2232),
            borderColor: color.withOpacity(0.3),
          ),
          child: SizedBox(
            height: 96, // 恢復統一高度，達成完美蜂巢拼合
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(fontSize: 10, color: color.withOpacity(0.9), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 管理模組項目 (蜂巢六角形)
  Widget _buildHoneycombModule(String label, IconData icon, Color color) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {}, // 之後可以加上跳轉邏輯
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0), // 統一間距以確保蜂巢完美對齊
          child: CustomPaint(
            painter: _HoneycombPainter(
              backgroundColor: const Color(0xFF1A2232),
              borderColor: color.withOpacity(0.3),
            ),
            child: SizedBox(
              height: 96, // 恢復統一高度，達成完美蜂巢拼合
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32), // 將圖示明顯放大
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white, height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 案件詳細資訊列
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
    final pictureBase64 = member['picture']?.toString();
    
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
                      backgroundImage: pictureBase64 != null && pictureBase64.isNotEmpty
                          ? MemoryImage(base64Decode(pictureBase64.split(',').last.replaceAll(RegExp(r'\s+'), '')))
                          : null,
                      child: (pictureBase64 == null || pictureBase64.isEmpty) ? Text(avatarChar, style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 20)) : null,
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
    final today = DateTime.now();
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final weekdayStr = '星期${weekdays[today.weekday - 1]}';
    final dateString = '${today.year}年${today.month}月${today.day}日 $weekdayStr';
    
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: _userPictureBase64 != null && _userPictureBase64!.isNotEmpty
                                    ? MemoryImage(base64Decode(_userPictureBase64!))
                                    : null,
                                child: _userPictureBase64 == null || _userPictureBase64!.isEmpty
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
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Hi, $_userName', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(dateString, style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_isSubscribed) ...[
                      Tooltip(
                        message: '新增工地',
                        child: ElevatedButton(
                          onPressed: () => AddConstructionDialog.show(context), // 呼叫獨立的靜態方法
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
                        onPressed: () => DispatchDialog.show(context), // 呼叫獨立的靜態方法
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
              onRefresh: _fetchData,
              color: const Color(0xFFE5BA73), // 金色轉圈圈
              backgroundColor: const Color(0xFF1A2232),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // 確保內容過少時依然可下拉
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 3. 今日出勤率儀表板 (在深色背景上的反白設計)
                    Container(
                      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return SizedBox(
                            width: 240,
                            height: 130, // 增加寬高，讓圓弧與文字保持更寬敞的距離
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                CustomPaint(
                                  size: const Size(240, 120), // 放大儀表板半圓弧
                                  painter: _DashboardGaugePainter(
                                    progress: _animation.value, // 動態更新進度
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('今日出勤率', style: TextStyle(fontSize: 13, color: Color(0xFF8A94A6), fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('${(_animation.value * 100).toInt()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 4), // 些微下壓，拉開文字與頂端圓弧的距離
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
            
            // 4. 四個統計框與管理模組 (穿插排版)
            Transform.translate(
              offset: const Offset(0, -20),
              child: Stack(
                children: [
                  // 管理模組 (蜂巢六角形，穿插在下方空格)
                  Padding(
                    padding: const EdgeInsets.only(top: 72.0, left: 8.0, right: 8.0), // 剛好是高度 96 的 3/4 (72)，完美無縫咬合
                    child: Row(
                      children: [
                        const Spacer(flex: 1), // 利用 Flex 比例讓中心點完美對齊菱形的縫隙
                        _buildHoneycombModule('零用金', Icons.account_balance_wallet_outlined, const Color(0xFFE5BA73)),
                        _buildHoneycombModule('成本分析', Icons.pie_chart_outline, Colors.blueAccent),
                        _buildHoneycombModule('出勤管理', Icons.payments_outlined, Colors.greenAccent),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                  // 四個統計框 (蜂巢六角形)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHoneycombStat('今日工地', '3', const Color(0xFFE5BA73)),
                        _buildHoneycombStat('總員工', '${_teamMembers.length}', Colors.blue.shade100),
                        _buildHoneycombStat('今日出工', '$workingCount', Colors.greenAccent),
                        _buildHoneycombStat('今日空班', '$idleCount', Colors.redAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 以下原本內容包裝在 Padding 中
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              
              // 5. 員工狀態 (待命/工作中)
              const Text('員工狀態', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              _isLoading
                  ? const SizedBox(
                      height: 64,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFE5BA73))), // 載入中動畫
                    )
                  : _teamMembers.isEmpty
                      ? const SizedBox(
                          height: 64,
                          child: Center(child: Text('目前團隊無成員', style: TextStyle(color: Color(0xFF8A94A6)))),
                        )
                      : SizedBox(
                      height: 64, // 增加一點高度容納卡片框
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _teamMembers.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          final isWorking = member['isWorking'] == true;
                          String avatarChar = member['name'].toString().isNotEmpty ? member['name'].toString().substring(0, 1) : '?';
                          final pictureBase64 = member['picture']?.toString();
                          
                          return GestureDetector(
                            onTap: () => _showEmployeeDetails(context, member, isWorking),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2232), // 獨立深色卡片
                                borderRadius: BorderRadius.circular(32), // 膠囊圓角
                                border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isWorking ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                    backgroundImage: pictureBase64 != null && pictureBase64.isNotEmpty
                                        ? MemoryImage(base64Decode(pictureBase64.split(',').last.replaceAll(RegExp(r'\s+'), '')))
                                        : null,
                                    child: (pictureBase64 == null || pictureBase64.isEmpty) ? Text(avatarChar, style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                      const SizedBox(height: 2),
                                      Text(
                                        isWorking ? '施工中' : '待命',
                                        style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 24),
              
              // 6. 即將到來案件 (點擊進入詳細頁面)
              const Text('即將到來案件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.only(bottom: 80), // 避免內容被 NavigationBar 遮擋
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2232), // 改為深色風格卡片
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.3), width: 1.5), // 金色外框
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CaseDetailPage()));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(child: Text('中山區辦公大樓空調維護', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8A94A6)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCaseInfoRow(Icons.calendar_today, '派工日期：2023-11-20', const Color(0xFFE65100)),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.location_on, '台北市中山區南京東路1段1號', Colors.red.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.people, '派工：測試員工1, 測試員工2', Colors.blue.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.note_alt_outlined, '派工備註：例行性空調保養，請攜帶A字梯', Colors.green.shade400),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ), // 補上 Padding 的結尾括號
                  ],
                ),
              ),
            ),
          ), // 補上 Expanded 的結尾括號
          ],
        ),
      );
  }
}

// --- 汽車儀表板風格出勤率 ---
class _DashboardGaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;

  _DashboardGaugePainter({required this.progress, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0; // 將線條調細
    final paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = (size.width - paint.strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 繪製背景圓弧 (半圓: pi 到 2pi)
    canvas.drawArc(rect, math.pi, math.pi, false, paint);

    if (progress > 0) {
      // 1. 繪製進度圓弧 (純金色，移除發光與漸層)
      paint.color = const Color(0xFFE5BA73);
      canvas.drawArc(rect, math.pi, math.pi * progress, false, paint);

      // 2. 在最前端畫一個白點 (保留末端白光)
      final tipAngle = math.pi + (math.pi * progress);
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      
      final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 1.5, dotPaint); // 乾淨的白點
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.backgroundColor != backgroundColor;
  }
}

// --- 蜂巢六角形背景繪製 ---
class _HoneycombPainter extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;

  _HoneycombPainter({required this.borderColor, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 正統蜂巢比例：尖端佔總高度的 1/4 (0.25)
    final double pointH = size.height * 0.25; 
    final path = Path();
    path.moveTo(size.width / 2, 0); // 頂部中間
    path.lineTo(size.width, pointH); // 右上角
    path.lineTo(size.width, size.height - pointH); // 右下角
    path.lineTo(size.width / 2, size.height); // 底部中間
    path.lineTo(0, size.height - pointH); // 左下角
    path.lineTo(0, pointH); // 左上角
    path.close();

    final fillPaint = Paint()..color = backgroundColor..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()..color = borderColor..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HoneycombPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor || oldDelegate.backgroundColor != backgroundColor;
  }
}