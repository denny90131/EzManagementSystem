import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Services/Authenticator/api_service.dart';
import '../Authenticator/Login.dart'; // 修正 Login.dart 的引入路徑
import 'Home/Setting/EditRegisterInfo.dart';

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
    }
    _fetchData(); // 無論如何都呼叫 _fetchData() 來更新資料和完整度狀態

    // 初始化儀表板動畫 (從 0 跑到 85%)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 播放時間 1.5 秒
    );
    _animation = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
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
    }
  }

  // 顯示設定選單 (點擊姓名大頭貼時觸發)
  void _showSettings(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: const Color(0xFF1A2232), // 卡片底色
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF121824),
                      backgroundImage: _userPictureBase64 != null && _userPictureBase64!.isNotEmpty
                          ? MemoryImage(base64Decode(_userPictureBase64!))
                          : null,
                      child: _userPictureBase64 == null || _userPictureBase64!.isEmpty
                          ? const Icon(Icons.person_outline, color: Color(0xFFE5BA73), size: 36)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            '${(_userCompany == null || _userCompany!.isEmpty || _userCompany == '.') ? '尚未填寫公司' : _userCompany} • '
                            '${(_userPosition == null || _userPosition!.isEmpty || _userPosition == '.') ? '尚未填寫職務' : _userPosition}',
                            style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14),
                          ),
                          if (_userPhone != null && _userPhone!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(_userPhone!, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Color(0xFFE5BA73)),
                title: const Text('編輯個人資料', style: TextStyle(color: Colors.white)),
                onTap: () {
                  // 點擊編輯個人資料時，如果資料不完整，可以顯示提示或直接導航
                  if (!_isProfileComplete) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('請完善您的個人資料！')));
                  }
                  Navigator.pop(sheetContext);
                  Navigator.push(parentContext, MaterialPageRoute(builder: (context) => EditProfileScreen(userData: _fullUserData)));
                },
                trailing: !_isProfileComplete ? const Icon(Icons.error, color: Colors.red, size: 20) : null, // 直接在 trailing 顯示驚嘆號
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('登出', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  // 1. 先關閉底部選單，避免阻擋導航
                  Navigator.pop(sheetContext);

                  // 2. 登出時必須清除儲存的 user_id，避免下次開啟自動登入
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('user_id');
                  
                  // 3. 返回登入畫面
                  if (!parentContext.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ), // 移除原有的 Positioned 元件
            ],
          ),
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

  // 彈出視窗專用的輸入框元件
  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8A94A6)),
        prefixIcon: Icon(icon, color: const Color(0xFF8A94A6)),
        filled: true,
        fillColor: const Color(0xFF121824),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
      ),
    );
  }

  // 顯示「新增工地」彈出視窗
  void _showAddSiteDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2232), // 深色卡片背景
          title: const Text('新增工地', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(nameController, '案件名稱', Icons.work_outline),
                const SizedBox(height: 12),
                _buildDialogTextField(addressController, '地址', Icons.location_on_outlined),
                const SizedBox(height: 12),
                _buildDialogTextField(notesController, '備註', Icons.note_alt_outlined, maxLines: 3),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Color(0xFF8A94A6))),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請填寫案件名稱')));
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已建立新工地：${nameController.text}')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black),
              child: const Text('確認新增', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 顯示「派工」彈出視窗
  void _showDispatchDialog(BuildContext context) {
    String? selectedSite;
    List<String> selectedEmployees = [];
    final TextEditingController dispatchNotesController = TextEditingController();

    // 模擬資料列表
    final List<String> availableSites = ['中山區辦公大樓空調維護', '信義區百貨管線重整', '大安區豪宅裝潢工程'];
    final List<String> availableEmployees = ['測試員工1', '測試員工2', '測試員工3', '測試員工4', '測試員工5'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2232), // 深色卡片背景
              title: const Text('派工', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('選擇派工工地', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedSite,
                      dropdownColor: const Color(0xFF121824),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF121824),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('請選擇工地', style: TextStyle(color: Color(0xFF8A94A6))),
                      items: availableSites.map((site) {
                        return DropdownMenuItem(value: site, child: Text(site));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSite = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('選擇派工人員 (可多選)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: availableEmployees.map((emp) {
                        final isSelected = selectedEmployees.contains(emp);
                        return FilterChip(
                          label: Text(emp, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE5BA73),
                          backgroundColor: const Color(0xFF121824),
                          checkmarkColor: Colors.black,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                selectedEmployees.add(emp);
                              } else {
                                selectedEmployees.remove(emp);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Color(0xFF8A94A6))),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSite == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請選擇工地')));
                      return;
                    }
                    if (selectedEmployees.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請至少選擇一位員工')));
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功派工 ${selectedEmployees.length} 人至 $selectedSite')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black),
                  child: const Text('確認派工', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 顯示員工詳細資訊的底部彈出視窗
  void _showEmployeeDetails(BuildContext context, int index, bool isWorking) {
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
                      child: Text('員${index + 1}', style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('測試員工 ${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
                _buildCaseInfoRow(Icons.phone_outlined, '0912-345-678', const Color(0xFFE5BA73)),
                const SizedBox(height: 12),
                _buildCaseInfoRow(Icons.contact_emergency_outlined, '緊急聯絡人: 王小明 (配偶) \n0987-654-321', const Color(0xFFE5BA73)),
                
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
                    const SizedBox(height: 20),
                    _ final TextEditingController dispatchNotesController = TextEditingController();
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
    
    // 模擬 7 天內的派工日期 (例如 3 天後)
    final upcomingDate = today.add(const Duration(days: 3));
    final upcomingDateStr = '${upcomingDate.month}月${upcomingDate.day}日';

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
                    Tooltip(
                      message: '新增工地',
                      child: ElevatedButton(
                        onPressed: () => _showAddSiteDialog(context),
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
                      onPressed: () => _showDispatchDialog(context),
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
                        _buildHoneycombStat('總員工', '20', Colors.blue.shade100),
                        _buildHoneycombStat('今日出工', '17', Colors.greenAccent),
                        _buildHoneycombStat('今日空班', '3', Colors.redAccent),
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
              SizedBox(
                height: 64, // 增加一點高度容納卡片框
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5, // 測試資料，加入多筆展示左右滑動效果
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final isWorking = index % 2 == 0; // 模擬資料邏輯
                    return GestureDetector(
                      onTap: () => _showEmployeeDetails(context, index, isWorking),
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
                              child: Text('員${index + 1}', style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('測試員工 ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
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
              const Text('即將到來 (7天內派工)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFE65100).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                child: const Text('距離 3 天', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8A94A6)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('中山區辦公大樓空調維護', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          _buildCaseInfoRow(Icons.calendar_today, '派工日期: $upcomingDateStr', const Color(0xFFE5BA73)),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.person_outline, '業主: 王董事長 (0912-345-678)', Colors.cyan.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.location_on_outlined, '工地地址: 台北市中山區南京東路1段1號', Colors.red.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.handshake_outlined, '發包人: 李承包 (0987-654-321)', Colors.orange.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.attach_money_outlined, '預算金額: NT\$ 50,000', Colors.green.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.edit_document, '訂單日期: 2023-11-10', Colors.teal.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.note_alt_outlined, '工地備註: 豪宅社區，請注意整潔。', Colors.grey.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.people_outline, '當日派工人員: 測試員工1, 測試員工2', Colors.purple.shade400),
                          const SizedBox(height: 10),
                          _buildCaseInfoRow(Icons.speaker_notes_outlined, '派工備註: 早上 9 點先到公司集合拿材料。', Colors.pink.shade300),
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

// --- 案件詳細頁面 (點擊案件卡片時導覽) ---
class CaseDetailPage extends StatelessWidget {
  const CaseDetailPage({super.key});

  Widget _buildDetailTile(IconData icon, String title, String subtitle, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 深色背景
      appBar: AppBar(
        title: const Text('案件詳情', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF121824), // 深色背景
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white12, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // 工作單標頭設計
          Center(
            child: Column(
              children: [
                const Icon(Icons.qr_code_scanner, size: 48, color: Color(0xFFE5BA73)), // 金色 QR Icon
                const SizedBox(height: 8),
                const Text('WORK ORDER #20231120-001', style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: Color(0xFF8A94A6), letterSpacing: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232), // 深色卡片
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.3), width: 1.5), // 金色外框
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(child: Text('中山區辦公大樓空調維護', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE65100).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('已排定', style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 票根虛線分隔
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate((constraints.constrainWidth() / 10).floor(), (index) => const SizedBox(width: 5, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white24)))),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDetailTile(Icons.person_outline, '業主', '王董事長 (0912-345-678)', Colors.cyan.shade400),
                  _buildDetailTile(Icons.location_on_outlined, '工地地址', '台北市中山區南京東路1段1號', Colors.red.shade400),
                  _buildDetailTile(Icons.handshake_outlined, '發包人', '李承包 (0987-654-321)', Colors.orange.shade400),
                  _buildDetailTile(Icons.attach_money_outlined, '預算金額', 'NT\$ 50,000', Colors.green.shade400),
                  _buildDetailTile(Icons.edit_document, '訂單日期', '2023-11-10', Colors.teal.shade400),
                  _buildDetailTile(Icons.calendar_today, '派工日期', '2023-11-20', const Color(0xFFE5BA73)),
                  _buildDetailTile(Icons.people_outline, '當日派工人員', '測試員工1, 測試員工2', Colors.purple.shade400),
                  _buildDetailTile(Icons.note_alt_outlined, '工地備註', '豪宅社區，請注意整潔。', Colors.grey.shade400),
                  _buildDetailTile(Icons.speaker_notes_outlined, '派工備註', '早上 9 點先到公司集合拿材料。', Colors.pink.shade300),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('現場照片', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232), // 深色卡片
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.3), width: 1.5), // 金色外框
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5BA73).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_a_photo, size: 32, color: Color(0xFFE5BA73)),
                  ),
                  const SizedBox(height: 12),
                  const Text('點擊上傳現場照片', style: TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('支援 JPG, PNG 格式', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('留言與回報', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: '輸入回報內容或留言...',
                  hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE5BA73), width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A2232), // 深色輸入框背景
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2232), // 深色卡片
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF8A94A6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('返回', style: TextStyle(fontSize: 16, color: Color(0xFF8A94A6), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('進度已回報')));
                    Navigator.pop(context); // 回報後返回
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5BA73), // 金色按鈕
                    foregroundColor: Colors.black, // 黑字
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('回報進度', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}