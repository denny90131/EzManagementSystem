import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../API/Team_api.dart';

class DispatchDialog extends StatefulWidget {
  final List<Map<String, String>> members; // 修改：用於接收外部傳入的成員列表 (UUID, Name)
  final List<Map<String, String>> sites;    // 新增：用於接收外部傳入的工地列表 (UUID, Name)
  const DispatchDialog({super.key, required this.members, required this.sites});

  // 提供一個靜態方法方便外部直接呼叫開啟對話框
  static void show(BuildContext context, {required List<Map<String, String>> members, required List<Map<String, String>> sites}) {
    showDialog(
      context: context,
      builder: (ctx) => DispatchDialog(members: members, sites: sites),
    );
  }

  @override
  State<DispatchDialog> createState() => _DispatchDialogState();
}

class _DispatchDialogState extends State<DispatchDialog> { // 修改：selectedSite 儲存 UUID
  String? selectedSiteId; // 儲存選中的工地 UUID
  List<String> selectedEmployees = [];
  final TextEditingController notesController = TextEditingController();
  final TextEditingController constructionItemController = TextEditingController(); // 新增：施工項目控制器
  final TextEditingController dateController = TextEditingController(
    text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
  );
  final TextEditingController startTimeController = TextEditingController(text: '08:00'); // 預設開始時間
  final TextEditingController endTimeController = TextEditingController(text: '17:00');   // 預設結束時間
  TimeOfDay? _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _endTime = const TimeOfDay(hour: 17, minute: 0);
  String? _errorMessage; // 新增：用於記錄與顯示錯誤提示

  @override
  void initState() {
    super.initState();
    // 檢查收到的成員和工地資料
    debugPrint('DispatchDialog received members: ${widget.members}');
    debugPrint('DispatchDialog received sites: ${widget.sites}');
  }

  @override
  void dispose() {
    notesController.dispose();
    constructionItemController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
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
                      value: selectedSiteId, // 使用 selectedSiteId
                      dropdownColor: const Color(0xFF121824),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF121824),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('請選擇工地', style: TextStyle(color: Color(0xFF8A94A6))),
                      items: widget.sites.map((site) {
                        return DropdownMenuItem(value: site['id'], child: Text(site['name'] ?? '未知工地')); // 防範 site['name'] 為 null
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSiteId = val;
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
                    const Text('派工時間區間', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0));
                              if (picked != null) {
                                setState(() {
                                  _startTime = picked;
                                  startTimeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '開始時間',
                              hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
                              prefixIcon: const Icon(Icons.access_time, color: Color(0xFF8A94A6)),
                              filled: true,
                              fillColor: const Color(0xFF121824),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                            ),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('至', style: TextStyle(color: Color(0xFF8A94A6)))),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0));
                              if (picked != null) {
                                setState(() {
                                  _endTime = picked;
                                  endTimeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '結束時間',
                              hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
                              prefixIcon: const Icon(Icons.access_time_filled, color: Color(0xFF8A94A6)),
                              filled: true,
                              fillColor: const Color(0xFF121824),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('選擇派工人員 (可多選)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    FutureBuilder<List<String>>( // 使用 Future.value 來處理傳入的成員列表
                      future: Future.value(widget.members.map((m) => m['name'] ?? '未知成員').toList()), // 防範 m['name'] 為 null
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFFE5BA73), strokeWidth: 2.0)));
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Text('目前無可派工之團隊成員', style: TextStyle(color: Colors.redAccent, fontSize: 13));
                        }

                        final availableEmployees = snapshot.data!;

                        return Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0, // 增加行間距
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
                    const Text('施工項目', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: constructionItemController,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '輸入施工項目（例如：天花板封板）...',
                        hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
                        filled: true,
                        fillColor: const Color(0xFF121824),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                      ),
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
          child: const Text('取消', style: TextStyle(color: Color(0xFF8A94A6), fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            if (selectedSiteId == null) { // 檢查 selectedSiteId
              setState(() => _errorMessage = '請選擇工地');
              return;
            }
            if (dateController.text.trim().isEmpty) {
              setState(() => _errorMessage = '請選擇派工日期');
              return;
            }
            if (startTimeController.text.isEmpty || endTimeController.text.isEmpty) {
              setState(() => _errorMessage = '請選擇完整的派工時間區間');
              return;
            }
            if (selectedEmployees.isEmpty) {
              setState(() => _errorMessage = '請至少選擇一位員工');
              return;
            }
            // 這裡可以處理派工邏輯，例如呼叫 API
            final selectedSiteName = widget.sites.firstWhere((s) => s['id'] == selectedSiteId, orElse: () => {'id': '', 'name': '未知工地'})['name'] ?? '未知工地'; // 防範找不到工地或工地名稱為 null

            setState(() => _errorMessage = null); // 清除錯誤提示
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功派工 ${selectedEmployees.length} 人至 $selectedSiteName\n日期：${dateController.text} ${startTimeController.text} - ${endTimeController.text}')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black),
          child: const Text('確認派工', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
