import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../API/Team_api.dart';

class DispatchDialog extends StatefulWidget {
  const DispatchDialog({super.key});

  // 提供一個靜態方法方便外部直接呼叫開啟對話框
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const DispatchDialog(),
    );
  }

  @override
  State<DispatchDialog> createState() => _DispatchDialogState();
}

class _DispatchDialogState extends State<DispatchDialog> {
  String? selectedSite;
  List<String> selectedEmployees = [];
  final TextEditingController notesController = TextEditingController();
  final TextEditingController dateController = TextEditingController(
    text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
  );
  String? _errorMessage; // 新增：用於記錄與顯示錯誤提示
  late Future<List<String>> teamMembersFuture;

  // 模擬資料列表
  final List<String> availableSites = ['中山區辦公大樓空調維護', '信義區百貨管線重整', '大安區豪宅裝潢工程'];

  @override
  void initState() {
    super.initState();
    teamMembersFuture = _fetchTeamMembers(); // 動態取得當前團隊的真實成員名單
  }

  // 從本機讀取當前團隊 ID 並取得成員資料
  Future<List<String>> _fetchTeamMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getString('active_team_uuid');
    if (teamId == null || teamId.isEmpty) return [];

    final rawMembers = await TeamApiService.getMemberTeam(teamId);
    if (rawMembers == null) return [];

    return rawMembers.map((m) {
      final profile = m['profile'] ?? {};
      // 解析後端傳來的名字，兼容大小寫
      return (profile['name'] ?? profile['Name'] ?? '未命名').toString();
    }).toList();
  }

  @override
  void dispose() {
    notesController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2232), // 深色卡片背景
      title: const Text('派工', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: SingleChildScrollView(
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
                    const Text('派工日期', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                          });
                        }
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF8A94A6)),
                        filled: true,
                        fillColor: const Color(0xFF121824),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('選擇派工人員 (可多選)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    FutureBuilder<List<String>>(
                      future: teamMembersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFFE5BA73), strokeWidth: 2.0)));
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('目前無可派工之團隊成員或無法載入', style: TextStyle(color: Colors.redAccent, fontSize: 13));
                        }

                        final availableEmployees = snapshot.data!;

                        return Wrap(
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
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('派工備註', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '輸入派工備註事項（例如：請攜帶A字梯）...',
                        hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
                        filled: true,
                        fillColor: const Color(0xFF121824),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
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
              setState(() => _errorMessage = '請選擇工地');
              return;
            }
            if (dateController.text.trim().isEmpty) {
              setState(() => _errorMessage = '請選擇派工日期');
              return;
            }
            if (selectedEmployees.isEmpty) {
              setState(() => _errorMessage = '請至少選擇一位員工');
              return;
            }
            setState(() => _errorMessage = null); // 清除錯誤提示
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功派工 ${selectedEmployees.length} 人至 $selectedSite\n日期：${dateController.text}')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black),
          child: const Text('確認派工', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
