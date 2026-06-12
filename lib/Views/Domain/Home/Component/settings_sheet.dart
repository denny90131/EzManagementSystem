import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Authenticator/Login.dart';
import '../Setting/EditRegisterInfo.dart';
import '../../../../Services/Subscription/api_service.dart';
import '../../../../Services/Invite/api_service.dart'; // 引入 Invite 團隊服務
import '../Setting/ManageSubscription.dart'; // 引入新分離的檔案
import '../Setting/InviteMember.dart'; // 引入邀請成員介面
import '../Setting/ManageMyTeam.dart'; // 引入管理我的團隊介面

class SettingsBottomSheet extends StatefulWidget {
  final String userName;
  final String? userPictureBase64;
  final String? userCompany;
  final String? userPosition;
  final String? userPhone;
  final bool isProfileComplete;
  final Map<String, dynamic>? fullUserData;
  final BuildContext parentContext; // Context from HomePage to navigate from
  final VoidCallback? onDataUpdated; // 回呼函數：當編輯完成返回時通知首頁更新資料

  const SettingsBottomSheet({
    super.key,
    required this.userName,
    this.userPictureBase64,
    this.userCompany,
    this.userPosition,
    this.userPhone,
    required this.isProfileComplete,
    this.fullUserData,
    required this.parentContext,
    this.onDataUpdated,
  });

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  bool _isLoadingTeams = true;
  List<Map<String, dynamic>> _teams = [];
  String? _selectedTeamId;
  String? _userId;
  ActivePlanModel? _activePlan; // 儲存當前團隊的訂閱狀態
  bool _isLoadingPlan = false; // 訂閱狀態載入中旗標

  @override
  void initState() {
    super.initState();
    _initTeams();
  }

  Future<void> _initTeams() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId != null) {
      _selectedTeamId = prefs.getString('active_team_uuid');
      await _fetchTeams();
    } else {
      if (mounted) setState(() => _isLoadingTeams = false);
    }
  }

  Future<void> _fetchTeams() async {
    if (!mounted) return;
    setState(() => _isLoadingTeams = true);
    try {
      final teamsData = await SubscriptionApiService.getTeams(_userId!);
      if (!mounted) return;
      
      setState(() {
        // 過濾掉 UUID 為空的異常資料，避免 DropdownButton 崩潰
        final validTeams = teamsData?.where((t) => t.teamUUID.isNotEmpty).toList() ?? [];
        _teams = validTeams.map<Map<String, dynamic>>((t) => {
          'TeamUUID': t.teamUUID,
          'TeamName': t.teamName.isNotEmpty ? t.teamName : '未命名團隊',
        }).toList();
        
        if (_teams.isNotEmpty) {
          if (_selectedTeamId == null || !_teams.any((t) => t['TeamUUID'] == _selectedTeamId)) {
            _selectedTeamId = _teams.first['TeamUUID'];
            _saveSelectedTeam(_selectedTeamId!);
          }
          
          // 拉取當前選擇團隊的訂閱狀態
          _fetchActivePlan(_selectedTeamId!);
        } else {
          _selectedTeamId = null;
          _activePlan = null;
        }
      });
    } catch (e) {
      print("API 請求發生異常: $e");
      if (mounted) _showError('無法取得團隊列表');
    } finally {
      if (mounted) setState(() => _isLoadingTeams = false);
    }
  }

  Future<void> _fetchActivePlan(String teamId) async {
    if (!mounted) return;
    setState(() => _isLoadingPlan = true);
    try {
      final plan = await SubscriptionApiService.getActivePlan(teamId);
      if (mounted) {
        setState(() => _activePlan = plan);
      }
    } catch (e) {
      print("獲取訂閱方案失敗: $e");
      if (mounted) setState(() => _activePlan = null);
    } finally {
      if (mounted) setState(() => _isLoadingPlan = false);
    }
  }

  Future<void> _saveSelectedTeam(String teamId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_team_uuid', teamId);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showCreateTeamDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2532),
        title: const Text('建立新團隊', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '輸入團隊名稱',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5BA73))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await _createNewTeam(name);
              }
            },
            child: const Text('建立', style: TextStyle(color: Color(0xFFE5BA73))),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewTeam(String teamName) async {
    if (_userId == null) return;
    if (!mounted) return;
    setState(() => _isLoadingTeams = true);
    
    try {
      final result = await SubscriptionApiService.createTeam(
        generatorUUID: _userId!,
        teamName: teamName,
      );
      
      if (!mounted) return;

      if (result.$1 == null) {
        // 自動將剛創建好的團隊設為當前選中團隊
        if (result.$2 != null) {
          _selectedTeamId = result.$2!.teamUUID;
          await _saveSelectedTeam(_selectedTeamId!);
        }
        
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(content: Text('團隊建立成功！'), duration: Duration(seconds: 2)),
        );
        await _fetchTeams(); // 重新取得最新列表
      } else {
        _showError(result.$1!);
      }
    } catch (e) {
      if (mounted) _showError('網路發生錯誤: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTeams = false);
    }
  }

  void _showSubscriptionDialog() {
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(const SnackBar(content: Text('請先選擇或建立一個團隊')));
      return;
    }

    final currentTeam = _teams.firstWhere(
      (t) => t['TeamUUID'] == _selectedTeamId,
      orElse: () => <String, dynamic>{'TeamName': '未知團隊'},
    );
    final String currentTeamName = currentTeam['TeamName'];

    // 呼叫我們剛剛分離出去的獨立 Widget
    ManageSubscriptionDialog.show(
      widget.parentContext,
      teamUUID: _selectedTeamId!,
      teamName: currentTeamName,
      onSubscriptionSuccess: () {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(const SnackBar(content: Text('訂閱成功！')));
        _fetchActivePlan(_selectedTeamId!); // 重新抓取訂閱狀態
        if (widget.onDataUpdated != null) widget.onDataUpdated!();
      },
    );
  }
  
  void _showJoinTeamDialog() {
    final TextEditingController controller = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2532),
          title: const Text('加入團隊', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('請輸入團隊邀請碼：', style: TextStyle(color: Color(0xFF8A94A6))),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, letterSpacing: 2.0),
                decoration: InputDecoration(
                  hintText: '例如: EZ-123456',
                  hintStyle: const TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5BA73))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: isSubmitting ? null : () async {
                final code = controller.text.trim();
                if (code.isEmpty) return;
                
                setDialogState(() => isSubmitting = true);
                
                if (_userId == null) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(const SnackBar(content: Text('無法取得使用者資訊，請重新登入')));
                  setDialogState(() => isSubmitting = false);
                  return;
                }
                
                // 呼叫真實 API 加入團隊
                final (isSuccess, message) = await ApiService.joinTeamByCode(code, _userId!);

                if (!mounted) return;

                if (isSuccess) {
                  Navigator.pop(ctx); // 關閉對話框
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                  _fetchTeams(); // 重新整理團隊列表 (取得剛加入的團隊資訊)
                } else {
                  setDialogState(() => isSubmitting = false); // 恢復按鈕狀態
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                }
              },
              child: isSubmitting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5BA73)))
                  : const Text('加入', style: TextStyle(color: Color(0xFFE5BA73))),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyTeamDialog() {
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(const SnackBar(content: Text('請先選擇或建立一個團隊')));
      return;
    }

    final currentTeam = _teams.firstWhere(
      (t) => t['TeamUUID'] == _selectedTeamId,
      orElse: () => <String, dynamic>{'TeamName': '未知團隊'},
    );
    final String currentTeamName = currentTeam['TeamName'];

    // 不關閉 BottomSheet，直接導航，這樣返回時才會回到原本的選單(大頭貼頁面)
    Navigator.push(
      widget.parentContext,
      CupertinoPageRoute(
        builder: (ctx) => ManageMyTeamPage(teamUUID: _selectedTeamId!, teamName: currentTeamName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) { // 'context' here is the sheetContextｓ
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
                  backgroundImage: widget.userPictureBase64 != null && widget.userPictureBase64!.isNotEmpty
                      ? MemoryImage(base64Decode(widget.userPictureBase64!.split(',').last.replaceAll(RegExp(r'\s+'), '')))
                      : null,
                  child: widget.userPictureBase64 == null || widget.userPictureBase64!.isEmpty
                      ? const Icon(Icons.person_outline, color: Color(0xFFE5BA73), size: 36)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 8),
                          // --- 動態顯示當前團隊訂閱狀態 ---
                          if (_isLoadingPlan)
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE5BA73)))
                          else if (_activePlan != null && _activePlan!.remainingDays > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)]),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('剩餘 ${_activePlan!.remainingDays.toInt()} 天', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1), // 半透明灰底
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('未訂閱', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(widget.userCompany == null || widget.userCompany!.isEmpty || widget.userCompany == '.') ? '尚未填寫公司' : widget.userCompany} • '
                        '${(widget.userPosition == null || widget.userPosition!.isEmpty || widget.userPosition == '.') ? '尚未填寫職務' : widget.userPosition}',
                        style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14),
                      ),
                      if (widget.userPhone != null && widget.userPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(widget.userPhone!, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                      ]
                    ],
                  ),
                ),
                // --- 快捷操作按鈕 (依據訂閱狀態切換) ---
                if (!_isLoadingPlan) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_activePlan != null && _activePlan!.remainingDays > 0)
                        // 已訂閱：顯示邀請成員
                        InkWell(
                          onTap: () {
                            final currentTeam = _teams.firstWhere(
                              (t) => t['TeamUUID'] == _selectedTeamId,
                              orElse: () => <String, dynamic>{'TeamName': '未知團隊'},
                            );
                            InviteMemberDialog.show(
                              widget.parentContext, 
                              teamUUID: _selectedTeamId!, 
                              teamName: currentTeam['TeamName'],
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5BA73).withOpacity(0.1),
                              border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.group_add_outlined, color: Color(0xFFE5BA73), size: 16),
                                SizedBox(width: 4),
                                Text('邀請成員', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        )
                      else
                        // 未訂閱：顯示升級方案
                        InkWell(
                          onTap: _showSubscriptionDialog, // 點擊直接開啟升級訂閱視窗
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5BA73).withOpacity(0.1),
                              border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.rocket_launch_outlined, color: Color(0xFFE5BA73), size: 16),
                                SizedBox(width: 4),
                                Text('升級方案', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // 加入團隊按鈕
                      InkWell(
                        onTap: _showJoinTeamDialog, // 點擊呼叫剛剛寫的彈窗方法
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login, color: Colors.white70, size: 16),
                              SizedBox(width: 4),
                              Text('加入團隊', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          
          // --- 當前操作團隊切換與建立區塊 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('當前操作團隊', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoadingTeams)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Color(0xFFE5BA73)),
                  ))
                else if (_teams.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('您尚未加入任何團隊', style: TextStyle(color: Colors.white70)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5BA73),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _showCreateTeamDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('建立團隊', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedTeamId,
                              dropdownColor: const Color(0xFF1E2532),
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5BA73)),
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              items: _teams.map((team) {
                                return DropdownMenuItem<String>(
                                  value: team['TeamUUID'],
                                  child: Text(team['TeamName'] ?? '未命名團隊'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedTeamId = val;
                                    _activePlan = null; // 切換團隊時，先清空舊的訂閱狀態避免混淆
                                  });
                                  _saveSelectedTeam(val);
                                  _fetchActivePlan(val); // 拉取新選擇團隊的訂閱方案
                                  // 切換團隊後，可考慮呼叫更新方法讓背後的頁面知道團隊已變更
                                  if (widget.onDataUpdated != null) widget.onDataUpdated!();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFFE5BA73)),
                          tooltip: '建立新團隊',
                          onPressed: _showCreateTeamDialog,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // 編輯個人資料
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFFE5BA73)),
            title: const Text('編輯個人資料', style: TextStyle(color: Colors.white)),
            onTap: () {
              if (!widget.isProfileComplete) {
                ScaffoldMessenger.of(widget.parentContext).showSnackBar(const SnackBar(content: Text('請完善您的個人資料！'), duration: Duration(seconds: 1))); // 顯示2秒
              }
              // 不關閉 BottomSheet，這樣從編輯頁面返回時才能回到大頭貼選單
              Navigator.push(widget.parentContext, CupertinoPageRoute(builder: (ctx) => EditProfileScreen(userData: widget.fullUserData))).then((_) {
                if (widget.onDataUpdated != null) widget.onDataUpdated!(); // 編輯完成返回後，觸發更新
              });
            },
            trailing: !widget.isProfileComplete ? const Icon(Icons.error, color: Colors.red, size: 20) : null,
          ),
          // 管理我的團隊
          ListTile(
            leading: const Icon(Icons.group, color: Color(0xFFE5BA73)),
            title: const Text('管理我的團隊', style: TextStyle(color: Colors.white)),
            onTap: _showMyTeamDialog,
          ),
          // 管理訂閱方案
          ListTile(
            leading: const Icon(Icons.subscriptions, color: Color(0xFFE5BA73)),
            title: const Text('管理我的訂閱', style: TextStyle(color: Colors.white)),
            onTap: _showSubscriptionDialog,
          ),
          // 登出
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('登出', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(context); // Close the bottom sheet
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_id');
              
              if (!widget.parentContext.mounted) return;
              Navigator.pushAndRemoveUntil(
                widget.parentContext,
                MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}