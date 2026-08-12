import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ez_manager/Views/Domain/Home/Management_Module/Dashboard.dart'; // 引入新的儀表板模組
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ez_manager/Views/Domain/Home/Management_Module/Employee_Status_Section.dart'; // 引入新的員工狀態模組'
import 'package:ez_manager/Views/Domain/Home/home_page_data_service.dart'; // 🚀 引入新的資料服務
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
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await HomePageDataService.fetchHomePageData(
        fetchUser: fetchUser,
        initialUserData: _fullUserData,
      );
      
      if (!mounted) return;

      if (data.needsRefetch) {
        _fetchData(fetchUser: false); // 如果服務標記需要重抓，則再次呼叫
        return;
      }

      setState(() {
        _userTeams = data.userTeams;
        _selectedTeamId = data.selectedTeamId;
        _isSubscribed = data.isSubscribed;
        _teamMembers = data.teamMembers;
        _sites = data.sites;
        _filteredSites = List.from(_sites);
        _isProfileComplete = data.isProfileComplete;

        if (data.fullUserData != null) {
          _fullUserData = data.fullUserData;
          _userName = _fullUserData!['name'] ?? '使用者';
          _userPictureBase64 = _fullUserData!['picture'];
          _userCompany = _fullUserData!['company'];
          _userPosition = _fullUserData!['position'];
          _userPhone = _fullUserData!['phoneNumber'];

          if (_userPictureBase64 != null && _userPictureBase64!.isNotEmpty) {
            Future(() {
              try {
                final bytes = base64Decode(_userPictureBase64!.split(',').last.replaceAll(RegExp(r'\s+'), ''));
                if (mounted) setState(() => _userPictureBytes = bytes);
              } catch (_) {}
            });
          }
        }
      });
      _filterSites(); // 更新完資料後執行過濾
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_userName == '載入中...') _userName = '無法載入';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                          sites: _sites.map((s) {
                            return {
                              'id': s['siteUUID']?.toString() ?? '', // 安全地轉換為 String，避免 null
                              'name': s['siteName']?.toString() ?? '', // 安全地轉換為 String，避免 null
                            };
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