import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../Services/Invite/api_service.dart';

class ManageMyTeamPage extends StatefulWidget {
  final String teamUUID;
  final String teamName;

  const ManageMyTeamPage({
    super.key,
    required this.teamUUID,
    required this.teamName,
  });

  @override
  State<ManageMyTeamPage> createState() => _ManageMyTeamPageState();
}

class _ManageMyTeamPageState extends State<ManageMyTeamPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    
    // TODO: 先不要串 API，用假資料代替
    await Future.delayed(const Duration(milliseconds: 800));
    final members = [
      {
        "memberUUID": "user-001", "name": "測試員工A", "permetionCode": 1, "salary": 2000, "remark": "資深木工師傅，自備貨車",
        "picture": null, // Base64 string or null
        "phoneNumber": "0912-345-678",
        "position": "木工",
        "iceName": "王美麗",
        "icePhoneNumber": "0987-654-321",
      },
      {
        "memberUUID": "user-002", "name": "測試員工B", "permetionCode": 2, "salary": 2500, "remark": "",
        "picture": null,
        "phoneNumber": "0922-333-444",
        "position": "油漆工",
        "iceName": "陳大明",
        "icePhoneNumber": "0977-654-321",
      },
      {
        "memberUUID": "user-003", "name": "測試員工C", "permetionCode": 3, "salary": 3200, "remark": "新人，需多留意安全",
        "picture": null,
        "phoneNumber": "0933-555-666",
        "position": "學徒",
        "iceName": "林小花",
        "icePhoneNumber": "0966-123-456",
      },
    ];
    
    setState(() {
      _members = members;
      _isLoading = false;
    });
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
                              DropdownMenuItem(value: 1, child: Text('權限等級 1 (一般)', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 2, child: Text('權限等級 2 (管理)', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 3, child: Text('權限等級 3 (最高)', style: TextStyle(color: Colors.white))),
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
                      const Text('員工備註', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
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
                      
                      // TODO: 先不要串 API，用假資料代替
                      await Future.delayed(const Duration(milliseconds: 500));
                      bool success = true; // 模擬成功
                          
                          if (success && mounted) {
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('成員設定已更新')));
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
                                  onPressed: () {
                                    // 執行刪除：將該成員從本地 _members 陣列中移除
                                    setState(() {
                                      _members.removeWhere((m) => m['memberUUID'] == member['memberUUID']);
                                    });
                                    Navigator.pop(confirmCtx); // 關閉確認視窗
                                    Navigator.pop(ctx); // 關閉編輯視窗
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已將 ${member['name']} 移出團隊')));
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

  // 顯示員工詳細資訊的彈出視窗
  void _showMemberDetailsDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2532),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 頂部頭像與名稱
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF121824),
                        // TODO: 之後可串接真實圖片 backgroundImage: member['picture'] != null ? MemoryImage(base64Decode(member['picture'])) : null,
                        child: member['picture'] == null ? const Icon(Icons.person, color: Color(0xFFE5BA73), size: 32) : null,
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
                  _buildDetailRow(Icons.work_outline, '擔任職務', member['position'] ?? ''),
                  _buildDetailRow(Icons.shield_outlined, '權限等級', '等級 ${member['permetionCode'] ?? 'N/A'}'),
                  _buildDetailRow(Icons.attach_money, '單日薪資', '\$${member['salary'] ?? 'N/A'}'),
                  
                  if (member['remark'] != null && member['remark'].isNotEmpty) ...[
                    const Divider(height: 24, color: Colors.white12),
                    _buildDetailRow(Icons.note_alt_outlined, '備註', member['remark'] ?? ''),
                  ],
                  
                  // 緊急聯絡人
                  if ((member['iceName'] != null && member['iceName'].isNotEmpty) || (member['icePhoneNumber'] != null && member['icePhoneNumber'].isNotEmpty)) ...[
                    const Divider(height: 24, color: Colors.white12),
                    const Text('緊急聯絡人', style: TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.person_outline, '聯絡人姓名', member['iceName'] ?? ''),
                    _buildDetailRow(Icons.phone_in_talk_outlined, '聯絡人手機', member['icePhoneNumber'] ?? ''),
                  ],

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
    if (value.isEmpty) return const SizedBox.shrink(); // 如果沒有值，則不顯示該行
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
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2532),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('管理我的團隊', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.teamName, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 頂部功能區段
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _handleGenerateInviteCode,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 8),
                    Text('產生團隊邀請碼', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ),
          
          // 成員列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5BA73)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return Dismissible(
                        key: Key(member['memberUUID'].toString()),
                        direction: DismissDirection.endToStart, // 僅允許由右向左滑動 (向左滑)
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
                                  onPressed: () => Navigator.pop(confirmCtx, true), // 回傳 true 確認刪除
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已將 ${member['name']} 移出團隊')));
                        },
                        child: Card(
                          color: const Color(0xFF1E2532),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: const Color(0xFF121824), child: const Icon(Icons.person, color: Color(0xFFE5BA73))),
                            title: Text(member['name'] ?? '未命名', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('權限: ${member['permetionCode']} | 薪資: \$${member['salary']}', style: const TextStyle(color: Color(0xFF8A94A6))),
                                if (member['remark'] != null && member['remark'].toString().isNotEmpty)
                                  Text('備註: ${member['remark']}', style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 12)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                              onPressed: () => _showEditMemberDialog(member),
                              tooltip: '編輯成員',
                            ),
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