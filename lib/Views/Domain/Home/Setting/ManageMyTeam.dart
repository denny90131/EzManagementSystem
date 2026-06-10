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
      {"memberUUID": "user-001", "name": "測試員工A", "permetionCode": 1, "salary": 2000},
      {"memberUUID": "user-002", "name": "測試員工B", "permetionCode": 2, "salary": 2500},
      {"memberUUID": "user-003", "name": "測試員工C", "permetionCode": 3, "salary": 3200},
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
                    
                    // TODO: 先不要串 API，用假資料代替
                    await Future.delayed(const Duration(milliseconds: 500));
                    bool success = true; // 模擬成功
                        
                        if (success && mounted) {
                          Navigator.pop(ctx);
                          _fetchMembers(); // 刷新列表
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('成員設定已更新')));
                        }
                      },
                      child: const Text('儲存設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                    Icon(Icons.qr_code_scanner, color: Colors.black),
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
                      return Card(
                        color: const Color(0xFF1E2532),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: const Color(0xFF121824), child: const Icon(Icons.person, color: Color(0xFFE5BA73))),
                          title: Text(member['name'] ?? '未命名', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('權限: ${member['permetionCode']} | 薪資: \$${member['salary']}', style: const TextStyle(color: Color(0xFF8A94A6))),
                          trailing: const Icon(Icons.edit, color: Colors.white54, size: 20),
                          onTap: () => _showEditMemberDialog(member),
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