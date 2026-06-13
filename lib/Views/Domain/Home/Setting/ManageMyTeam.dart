import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../API/Invite_api.dart';
import '../../../../API/Team_api.dart';
import '../../../../API/Subscribe_api.dart'; // 引入訂閱狀態服務

class ManageMyTeamPage extends StatefulWidget {
  final String teamUUID;
  final String teamName;
  final bool isOwner;

  const ManageMyTeamPage({
    super.key,
    required this.teamUUID,
    required this.teamName,
    this.isOwner = false,
  });

  @override
  State<ManageMyTeamPage> createState() => _ManageMyTeamPageState();
}

class _ManageMyTeamPageState extends State<ManageMyTeamPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String _currentUserId = '';
  bool _isSubscribed = false; // 新增訂閱狀態記錄

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id') ?? '';

    final rawMembers = await TeamApiService.getMemberTeam(widget.teamUUID);
    final activePlan = await SubscriptionApiService.getActivePlan(widget.teamUUID);
    
    // 判斷團隊是否正在訂閱期間內
    final isSub = activePlan != null && activePlan.remainingDays > 0;
    
    if (rawMembers != null) {
      final parsedMembers = rawMembers.map<Map<String, dynamic>>((m) {
        final teamInfo = m['teamInfo'] ?? m['TeamInfo'] ?? {};
        final profile = m['profile'] ?? m['Profile'] ?? {};
        return {
          "memberUUID": teamInfo['memberUUID'] ?? teamInfo['MemberUUID'] ?? profile['index'] ?? profile['Index'] ?? '',
          "name": profile['name'] ?? profile['Name'] ?? '未命名',
          "permetionCode": teamInfo['permissionCode'] ?? teamInfo['PermissionCode'] ?? 1,
          "salary": teamInfo['salary'] ?? teamInfo['Salary'] ?? 2000,
          "isCreator": teamInfo['isCreator'] ?? teamInfo['IsCreator'] ?? false,
          "role": teamInfo['role'] ?? teamInfo['Role'] ?? 'Member',
          // 分開儲存團隊備註與個人備註
          "remark": teamInfo['note'] ?? teamInfo['Note'] ?? '', // 團隊專屬備註
          "personalNote": profile['note'] ?? profile['Note'] ?? '', // 個人基本資料備註
          "picture": profile['picture'] ?? profile['Picture'],
          "phoneNumber": profile['phoneNumber'] ?? profile['PhoneNumber'] ?? '',
          "position": profile['position'] ?? profile['Position'] ?? '',
          "iceName": profile['iceName'] ?? profile['ICEName'] ?? '',
          "icePhoneNumber": profile['icePhoneNumber'] ?? profile['ICEPhoneNumber'] ?? '',
          "company": profile['company'] ?? profile['Company'] ?? '',
          "email": profile['email'] ?? profile['Email'] ?? '',
          "address": profile['address'] ?? profile['Address'] ?? '',
          "birth": profile['birth'] ?? profile['Birth'] ?? '',
          "blood": profile['blood'] ?? profile['Blood'] ?? '',
          "geneticHistory": profile['geneticHistory'] ?? profile['GeneticHistory'] ?? '',
          "gender": profile['gender'] ?? profile['Gender'] ?? '',
          "iceRelation": profile['iceRelation'] ?? profile['ICERelation'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _members = parsedMembers;
          _isSubscribed = isSub; // 儲存訂閱狀態
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法載入團隊成員')));
      }
    }
  }

  Future<void> _handleGenerateInviteCode() async {
    // 呼叫真實 API 產生邀請碼
    final code = await ApiService.generateInviteCode(widget.teamUUID);
    
    if (!mounted) return;

    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('產生邀請碼失敗，請稍後再試')));
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2532),
          title: const Text('限時邀請碼', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('請將以下邀請碼提供給新成員，此邀請碼將在 3 天後失效：', style: TextStyle(color: Color(0xFF8A94A6))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF121824),
                  border: Border.all(color: const Color(0xFFE5BA73)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFFE5BA73)),
                      tooltip: '複製邀請碼',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('邀請碼已複製到剪貼簿')));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('關閉', style: TextStyle(color: Colors.white70)),
            )
          ],
        ),
      );
    }
  }

  void _showEditMemberDialog(Map<String, dynamic> member) {
    int currentPermission = member['permetionCode'] ?? 1;
    final TextEditingController salaryController = TextEditingController(text: member['salary']?.toString() ?? '2000');
    final TextEditingController remarkController = TextEditingController(text: member['remark']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2532),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('編輯成員：${member['name'] ?? '未命名'}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      
                      // 權限設定
                      const Text('設定權限等級', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121824),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: currentPermission,
                            dropdownColor: const Color(0xFF1E2532),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5BA73)),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('工班師傅', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 2, child: Text('案場經理', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 3, child: Text('公司核心', style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => currentPermission = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 薪資設定
                      const Text('設定單日薪資', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: salaryController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF121824),
                          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF8A94A6)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 備註設定
                      const Text('團隊備註', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: remarkController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF121824),
                          prefixIcon: const Icon(Icons.note_alt_outlined, color: Color(0xFF8A94A6)),
                          hintText: '輸入備註 (例如：專長、聯絡習慣...)',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 32),
  
                      // 儲存按鈕
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5BA73),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          int newSalary = int.tryParse(salaryController.text) ?? 2000;
                          String newRemark = remarkController.text.trim();
                      
                          // 呼叫 API 編輯成員
                          final prefs = await SharedPreferences.getInstance();
                          final executorId = prefs.getString('user_id') ?? '';
                          
                          final (isSuccess, message) = await TeamApiService.editMemberFromTeam(
                            teamUuid: widget.teamUUID,
                            executorMemberUuid: executorId,
                            targetMemberUuid: member['memberUUID'],
                            permissionCode: currentPermission,
                            salary: newSalary,
                            note: newRemark,
                          );
                          
                          if (!mounted) return;
                          
                          if (isSuccess) {
                            // 更新本地狀態以馬上反映變更 (不重新抓取 mock 假資料以免資料被覆蓋回去)
                            setState(() {
                              int index = _members.indexWhere((m) => m['memberUUID'] == member['memberUUID']);
                              if (index != -1) {
                                _members[index] = {
                                  ..._members[index],
                                  'permetionCode': currentPermission,
                                  'salary': newSalary,
                                  'remark': newRemark,
                                };
                              }
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                          }
                        },
                        child: const Text('儲存設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 16),
                      
                      // 移除成員按鈕
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (confirmCtx) => AlertDialog(
                              backgroundColor: const Color(0xFF1E2532),
                              title: const Text('移除成員', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              content: Text('確定要將「${member['name']}」移出團隊嗎？此動作無法復原。', style: const TextStyle(color: Color(0xFF8A94A6))),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmCtx),
                                  child: const Text('取消', style: TextStyle(color: Colors.white70)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final executorId = prefs.getString('user_id') ?? '';

                                    final (isSuccess, message) = await TeamApiService.deleteMemberFromTeam(
                                      teamUuid: widget.teamUUID,
                                      executorMemberUuid: executorId,
                                      targetMemberUuid: member['memberUUID'],
                                    );

                                    if (!mounted) return;

                                    if (isSuccess) {
                                      setState(() {
                                        _members.removeWhere((m) => m['memberUUID'] == member['memberUUID']);
                                      });
                                      Navigator.pop(confirmCtx); // 關閉確認視窗
                                      Navigator.pop(ctx); // 關閉編輯視窗
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                                    } else {
                                      Navigator.pop(confirmCtx);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                                    }
                                  },
                                  child: const Text('確定移除', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('將此成員移出團隊'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 檢查當前使用者是否為創辦者
  bool get _isCurrentUserCreator {
    if (widget.isOwner) return true;
    try {
      final currentUser = _members.firstWhere((m) => m['memberUUID'] == _currentUserId);
      return currentUser['isCreator'] == true || currentUser['permetionCode'] == 999;
    } catch (e) {
      return false;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr.startsWith('1900')) return '';
    if (dateStr.contains('T')) {
      return dateStr.split('T')[0];
    }
    return dateStr;
  }

  String _getPermissionName(dynamic code) {
    if (code == 1 || code == '1') return '工班師傅';
    if (code == 2 || code == '2') return '案場經理';
    if (code == 3 || code == '3') return '公司核心';
    if (code == 999 || code == '999') return '團隊創辦者';
    return '未知等級 ($code)';
  }

  // 顯示員工詳細資訊的彈出視窗
  void _showMemberDetailsDialog(Map<String, dynamic> member) {
    final bool isCurrentUserCreator = _isCurrentUserCreator;
    final bool isTargetCreator = member['isCreator'] == true || member['permetionCode'] == 999;
    final bool isSelf = member['memberUUID'] == _currentUserId;
    
    // 創辦者能編輯他人(非創辦者)
    final bool canEdit = isCurrentUserCreator && !isTargetCreator;
    // 創辦者可看所有人薪資權限，普通人只能看自己的，且所有人都看不到創辦者的薪資權限
    final bool canSeeSalaryAndPermission = (isCurrentUserCreator || isSelf) && !isTargetCreator;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2532),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 頂部拖曳指示條，提示使用者可以往下拉關閉
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // 頂部頭像與名稱
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF121824),
                        backgroundImage: member['picture'] != null && member['picture'].toString().isNotEmpty
                            ? MemoryImage(base64Decode(member['picture'].toString().split(',').last.replaceAll(RegExp(r'\s+'), '')))
                            : null,
                        child: (member['picture'] == null || member['picture'].toString().isEmpty) ? const Icon(Icons.person, color: Color(0xFFE5BA73), size: 32) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          member['name'] ?? '未命名',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32, color: Colors.white12),

                  // 詳細資料
                  _buildDetailRow(Icons.phone_outlined, '手機號碼', member['phoneNumber'] ?? ''),
                  _buildDetailRow(Icons.email_outlined, '聯絡信箱', member['email'] ?? ''),
                  _buildDetailRow(Icons.business_outlined, '公司名稱', member['company'] ?? ''),
                  _buildDetailRow(Icons.work_outline, '擔任職務', member['position'] ?? ''),
                  if (canSeeSalaryAndPermission)
                    _buildDetailRow(Icons.shield_outlined, '權限職位', _getPermissionName(member['permetionCode'])),
                  _buildDetailRow(Icons.wc_outlined, '性別', member['gender'] ?? ''),
                  _buildDetailRow(Icons.cake_outlined, '生日', _formatDate(member['birth'])),
                  _buildDetailRow(Icons.bloodtype_outlined, '血型', member['blood'] ?? ''),
                  _buildDetailRow(Icons.home_work_outlined, '聯絡地址', member['address'] ?? ''),
                  _buildDetailRow(Icons.medical_services_outlined, '遺傳病史', member['geneticHistory'] ?? ''),
                  if (canSeeSalaryAndPermission)
                    _buildDetailRow(Icons.attach_money, '單日薪資', '\$${member['salary'] ?? 'N/A'}'),
                  
                  const Divider(height: 24, color: Colors.white12),
                  _buildDetailRow(Icons.note_alt_outlined, '團隊備註', member['remark'] ?? ''),
                  _buildDetailRow(Icons.assignment_ind_outlined, '個人備註', member['personalNote'] ?? ''),
                  
                  // 緊急聯絡人
                  const Divider(height: 24, color: Colors.white12),
                  const Text('緊急聯絡人', style: TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.person_outline, '聯絡人姓名', 
                      '${member['iceName'] ?? ''} ${member['iceRelation'] != null && member['iceRelation'].toString().isNotEmpty ? '(${member['iceRelation']})' : ''}'.trim()
                  ),
                  _buildDetailRow(Icons.phone_in_talk_outlined, '聯絡人手機', member['icePhoneNumber'] ?? ''),

                  const SizedBox(height: 32),

                  // 操作按鈕
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('關閉', style: TextStyle(color: Color(0xFF8A94A6))),
                        ),
                      ),
                      if (canEdit) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('編輯'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE5BA73),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx); // 關閉詳細資訊視窗
                              _showEditMemberDialog(member); // 開啟編輯視窗
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 建立詳細資訊列的輔助元件
  Widget _buildDetailRow(IconData icon, String label, String value) {
    final displayValue = value.trim().isEmpty ? '-' : value; // 若無值則顯示 '-'，保持版面一致
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8A94A6), size: 18),
          const SizedBox(width: 16),
          SizedBox(
            width: 80, // 固定標籤寬度以對齊
            child: Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14)),
          ),
          Expanded(
            child: Text(displayValue, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUserCreator = _isCurrentUserCreator;

    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2532),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('管理我的團隊', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.teamName, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 頂部功能區段
          if (isCurrentUserCreator)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: _isSubscribed ? _handleGenerateInviteCode : () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('團隊尚未訂閱，無法產生邀請碼')));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: _isSubscribed 
                        ? const LinearGradient(colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)])
                        : null,
                    color: _isSubscribed ? null : Colors.white12, // 未訂閱時改用半透明灰底
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isSubscribed) ...[
                        const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(_isSubscribed ? '產生團隊邀請碼' : '團隊尚未訂閱，無法產生邀請碼', 
                          style: TextStyle(color: _isSubscribed ? Colors.black : Colors.white54, fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
          
          // 成員列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5BA73)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final bool isTargetCreator = member['isCreator'] == true || member['permetionCode'] == 999;
                      final bool isSelf = member['memberUUID'] == _currentUserId;
                      final bool canEdit = isCurrentUserCreator && !isTargetCreator;
                      final bool canSeeSalaryAndPermission = (isCurrentUserCreator || isSelf) && !isTargetCreator;

                      return Dismissible(
                        key: Key(member['memberUUID'].toString()),
                        direction: canEdit ? DismissDirection.endToStart : DismissDirection.none, // 無權限則禁用滑動刪除
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (direction) async {
                          // 彈出確認視窗，避免誤觸滑動刪除
                          return await showDialog<bool>(
                            context: context,
                            builder: (confirmCtx) => AlertDialog(
                              backgroundColor: const Color(0xFF1E2532),
                              title: const Text('移除成員', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              content: Text('確定要將「${member['name']}」移出團隊嗎？此動作無法復原。', style: const TextStyle(color: Color(0xFF8A94A6))),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmCtx, false), // 回傳 false 取消刪除
                                  child: const Text('取消', style: TextStyle(color: Colors.white70)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final executorId = prefs.getString('user_id') ?? '';

                                    final (isSuccess, message) = await TeamApiService.deleteMemberFromTeam(
                                      teamUuid: widget.teamUUID,
                                      executorMemberUuid: executorId,
                                      targetMemberUuid: member['memberUUID'],
                                    );

                                    if (!mounted) return;

                                    if (isSuccess) {
                                      Navigator.pop(confirmCtx, true); // 回傳 true 讓外層 Dismissible 繼續刪除動畫
                                    } else {
                                      Navigator.pop(confirmCtx, false); // 回傳 false 取消刪除動畫
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                                    }
                                  },
                                  child: const Text('確定移除', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          // 執行刪除動作並更新畫面
                          setState(() {
                            _members.removeWhere((m) => m['memberUUID'] == member['memberUUID']);
                          });
                          // SnackBar 在刪除 API 成功後處理即可
                        },
                        child: Card(
                          color: isTargetCreator ? const Color(0xFF2A2216) : const Color(0xFF1E2532),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isTargetCreator ? const BorderSide(color: Color(0xFFE5BA73), width: 1.5) : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF121824),
                              backgroundImage: member['picture'] != null && member['picture'].toString().isNotEmpty
                                  ? MemoryImage(base64Decode(member['picture'].toString().split(',').last.replaceAll(RegExp(r'\s+'), '')))
                                  : null,
                              child: (member['picture'] == null || member['picture'].toString().isEmpty) ? const Icon(Icons.person, color: Color(0xFFE5BA73)) : null),
                            title: Text(member['name'] ?? '未命名', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isTargetCreator)
                                  const Text('👑 團隊創辦者', style: TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.bold))
                                else if (canSeeSalaryAndPermission)
                                  Text('權限: ${_getPermissionName(member['permetionCode'])} | 薪資: \$${member['salary']}', style: const TextStyle(color: Color(0xFF8A94A6)))
                                else
                                  const Text('團員', style: TextStyle(color: Color(0xFF8A94A6))),
                                
                                const SizedBox(height: 4),
                                Text(
                                  '手機: ${member['phoneNumber']?.toString().trim().isNotEmpty == true ? member['phoneNumber'] : '-'}',
                                  style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                                ),

                                if (member['remark'] != null && member['remark'].toString().isNotEmpty)
                                  Text('團隊備註: ${member['remark']}', style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 12)),
                                if (member['personalNote'] != null && member['personalNote'].toString().isNotEmpty)
                                  Text('個人備註: ${member['personalNote']}', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                              ],
                            ),
                            trailing: canEdit ? IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                                onPressed: () => _showEditMemberDialog(member),
                                tooltip: '編輯成員',
                              ) : null,
                            onTap: () => _showMemberDetailsDialog(member),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}