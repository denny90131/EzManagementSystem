import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ReportPage({super.key, this.userData});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ImagePicker _picker = ImagePicker();
  
  DateTime? _clockInTime; // 記錄上班打卡時間
  DateTime? _clockOutTime; // 記錄下班打卡時間

  String? _selectedSiteForClockIn; // 新增：記錄選擇的打卡工地
  // 模擬工地列表 (未來可改由 API 取得該使用者的派工清單)
  final List<String> _availableSites = ['中山區辦公大樓空調維護', '信義區百貨管線重整', '大安區豪宅裝潢工程'];

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2232),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFE5BA73).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: const Color(0xFFE5BA73), size: 24),
              ),
              const SizedBox(width: 16),
                Text(label, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE5BA73))),
        ],
      ),
    );
  }

  // 建立打卡按鈕的輔助元件
  Widget _buildClockButton({required String title, required DateTime? time, required IconData icon, required Color color, required VoidCallback? onTap}) {
    final hasClocked = time != null;
    final timeStr = hasClocked ? "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}" : "--:--";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: hasClocked ? color.withOpacity(0.1) : const Color(0xFF121824),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasClocked ? color.withOpacity(0.5) : Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: hasClocked ? color : const Color(0xFF8A94A6), size: 28),
            const SizedBox(height: 8),
            Text(timeStr, style: TextStyle(color: hasClocked ? Colors.white : const Color(0xFF8A94A6), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: hasClocked ? color : const Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 建立打卡區塊
  Widget _buildClockInCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2232),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_filled, color: Color(0xFFE5BA73), size: 20),
              SizedBox(width: 8),
              Text('今日出勤打卡', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
        
        // 新增打卡工地選擇下拉選單
        DropdownButtonFormField<String>(
          value: _selectedSiteForClockIn,
          dropdownColor: const Color(0xFF1A2232),
          // 已經打卡後，就不允許更改工地
          onChanged: _clockInTime == null ? (val) => setState(() => _selectedSiteForClockIn = val) : null,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: '選擇打卡工地',
            labelStyle: const TextStyle(color: Color(0xFF8A94A6)),
            prefixIcon: const Icon(Icons.domain_outlined, color: Color(0xFF8A94A6)),
            filled: true,
            fillColor: const Color(0xFF121824),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
          ),
          items: _availableSites.map((String site) => DropdownMenuItem<String>(value: site, child: Text(site))).toList(),
        ),
        const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildClockButton(title: '上班打卡', time: _clockInTime, icon: Icons.login, color: Colors.greenAccent, onTap: _clockInTime == null ? () {
                  if (_selectedSiteForClockIn == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先選擇打卡工地！')));
                    return;
                  }
                    setState(() => _clockInTime = DateTime.now());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('上班打卡成功！')));
                  } : null),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildClockButton(title: '下班打卡', time: _clockOutTime, icon: Icons.logout, color: Colors.orangeAccent, onTap: (_clockInTime != null && _clockOutTime == null) ? () {
                    setState(() => _clockOutTime = DateTime.now());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下班打卡成功！辛苦了！')));
                  } : null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 建立表單輸入框的輔助元件
  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
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

  // 建立表單下拉選單的輔助元件
  Widget _buildDialogDropdownField(String label, IconData icon, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1A2232),
      onChanged: onChanged,
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
      items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
    );
  }

  // 顯示「新增回報」的底部彈出視窗
  void _showAddReportBottomSheet(BuildContext context, String siteName) {
    final dateController = TextEditingController(text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}");
    String? selectedWeather;
    
    // 動態表單狀態
    List<Map<String, dynamic>> constructionRecords = [];
    List<Map<String, dynamic>> materialRecords = [];
    bool isLogPrivate = false;
    final logController = TextEditingController();
    List<XFile> attachedImages = [];

    void addConstructionRecord(StateSetter setModalState) {
      setModalState(() {
        constructionRecords.add({
          'trade': null,
          'vendorCtrl': TextEditingController(),
          'workersCtrl': TextEditingController(),
          'notesCtrl': TextEditingController(),
        });
      });
    }

    void addMaterialRecord(StateSetter setModalState) {
      setModalState(() {
        materialRecords.add({
          'supplierCtrl': TextEditingController(),
          'itemCtrl': TextEditingController(),
          'qtyCtrl': TextEditingController(),
          'unit': null,
          'notesCtrl': TextEditingController(),
        });
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // 首次開啟時預設各加一筆空資料
            if (constructionRecords.isEmpty && materialRecords.isEmpty) {
              addConstructionRecord(setModalState);
              addMaterialRecord(setModalState);
            }

            // 處理選擇圖片
            Future<void> pickRecordImages(ImageSource source) async {
              try {
                if (source == ImageSource.gallery) {
                  final List<XFile> images = await _picker.pickMultiImage();
                  if (images.isNotEmpty) setModalState(() => attachedImages.addAll(images));
                } else {
                  final XFile? image = await _picker.pickImage(source: source);
                  if (image != null) setModalState(() => attachedImages.add(image));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法存取相機或相簿')));
              }
            }

            void showImageSource() {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1A2232),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (BuildContext ctx2) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE5BA73)),
                        title: const Text('從相簿選擇 (可多選)', style: TextStyle(color: Colors.white)),
                        onTap: () { Navigator.pop(ctx2); pickRecordImages(ImageSource.gallery); },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                        title: const Text('拍照', style: TextStyle(color: Colors.white)),
                        onTap: () { Navigator.pop(ctx2); pickRecordImages(ImageSource.camera); },
                      ),
                    ],
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(top: 60.0, bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A2232),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 頂部標題列
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text('回報：$siteName', 
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('已成功提交回報')));
                                },
                                child: const Text('儲存', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 可滾動內容區塊
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. 基本資訊
                            const Text('基本資訊', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _buildDialogTextField(dateController, '工作日期', Icons.calendar_today_outlined, readOnly: true, onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                              if (picked != null) setModalState(() => dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                            }),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: selectedWeather,
                              dropdownColor: const Color(0xFF1A2232),
                              onChanged: (val) => setModalState(() => selectedWeather = val),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: '天氣',
                                labelStyle: const TextStyle(color: Color(0xFF8A94A6)),
                                prefixIcon: const Icon(Icons.cloud_outlined, color: Color(0xFF8A94A6)),
                                filled: true,
                                fillColor: const Color(0xFF121824),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                              ),
                              items: [
                                {'label': '晴天', 'icon': Icons.wb_sunny},
                                {'label': '雨天', 'icon': Icons.water_drop},
                                {'label': '雷雨交加', 'icon': Icons.thunderstorm},
                                {'label': '龍捲風', 'icon': Icons.cyclone},
                              ].map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt['label'] as String,
                                  child: Row(
                                    children: [
                                      Icon(opt['icon'] as IconData, color: const Color(0xFFE5BA73), size: 20),
                                      const SizedBox(width: 12),
                                      Text(opt['label'] as String),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 32, color: Colors.white12),

                            // 2. 施工紀錄
                            const Text('施工紀錄', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...List.generate(constructionRecords.length, (index) {
                              final rec = constructionRecords[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('紀錄 #${index + 1}', style: const TextStyle(color: Color(0xFF8A94A6), fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => setModalState(() => constructionRecords.removeAt(index)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDialogDropdownField('工種', Icons.category_outlined, ['泥作', '木作', '水電', '油漆', '空調', '清潔', '其他'], rec['trade'], (val) => setModalState(() => rec['trade'] = val)),
                                    const SizedBox(height: 12),
                                    _buildDialogTextField(rec['vendorCtrl'], '廠商名稱', Icons.business_outlined),
                                    const SizedBox(height: 12),
                                    _buildDialogTextField(rec['workersCtrl'], '出工數', Icons.people_outline, keyboardType: TextInputType.number),
                                    const SizedBox(height: 12),
                                    _buildDialogTextField(rec['notesCtrl'], '備註', Icons.note_alt_outlined),
                                  ],
                                ),
                              );
                            }),
                            OutlinedButton.icon(
                              onPressed: () => addConstructionRecord(setModalState),
                              icon: const Icon(Icons.add, color: Color(0xFFE5BA73)),
                              label: const Text('新增施工紀錄', style: TextStyle(color: Color(0xFFE5BA73))),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Color(0xFFE5BA73)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                            const Divider(height: 32, color: Colors.white12),

                            // 3. 進/退料紀錄
                            const Text('進/退料紀錄', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...List.generate(materialRecords.length, (index) {
                              final rec = materialRecords[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('物料 #${index + 1}', style: const TextStyle(color: Color(0xFF8A94A6), fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: () => setModalState(() => materialRecords.removeAt(index)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDialogTextField(rec['supplierCtrl'], '供應商名稱', Icons.local_shipping_outlined),
                                    const SizedBox(height: 12),
                                    _buildDialogTextField(rec['itemCtrl'], '品項 / 型號', Icons.inventory_2_outlined),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(flex: 2, child: _buildDialogTextField(rec['qtyCtrl'], '數量', Icons.numbers, keyboardType: TextInputType.number)),
                                        const SizedBox(width: 8),
                                        Expanded(flex: 1, child: _buildDialogDropdownField('單位', Icons.straighten, ['個', '批', '式', '箱', '台', '公尺', '平方公尺', '其他'], rec['unit'], (val) => setModalState(() => rec['unit'] = val))),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDialogTextField(rec['notesCtrl'], '備註', Icons.note_alt_outlined),
                                  ],
                                ),
                              );
                            }),
                            OutlinedButton.icon(
                              onPressed: () => addMaterialRecord(setModalState),
                              icon: const Icon(Icons.add, color: Color(0xFFE5BA73)),
                              label: const Text('新增進/退料紀錄', style: TextStyle(color: Color(0xFFE5BA73))),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), side: const BorderSide(color: Color(0xFFE5BA73)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                            const Divider(height: 32, color: Colors.white12),

                            // 4. 工務日誌與照片
                            const Text('工務日誌', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(isLogPrivate ? Icons.visibility_off_outlined : Icons.public, color: isLogPrivate ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)),
                                    const SizedBox(width: 8),
                                    Text(isLogPrivate ? '此日誌為非公開 (內部)' : '此日誌為公開 (業主可見)', style: TextStyle(color: isLogPrivate ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6), fontSize: 14)),
                                  ],
                                ),
                                Switch(value: isLogPrivate, activeColor: const Color(0xFFE5BA73), onChanged: (val) => setModalState(() => isLogPrivate = val)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDialogTextField(logController, '填寫日誌與會議紀錄...', Icons.edit_document, maxLines: 4),
                            const SizedBox(height: 16),
                            
                            // 照片列表與上傳按鈕
                            if (attachedImages.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: List.generate(attachedImages.length, (i) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 72, height: 72,
                                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(attachedImages[i].path)), fit: BoxFit.cover)),
                                        ),
                                        Positioned(
                                          top: 0, right: 0,
                                          child: GestureDetector(
                                            onTap: () => setModalState(() => attachedImages.removeAt(i)),
                                            child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                          ),
                                        )
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: showImageSource,
                              icon: const Icon(Icons.image_outlined, color: Color(0xFF8A94A6)),
                              label: const Text('附加照片', style: TextStyle(color: Color(0xFF8A94A6))),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.white12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ],
                        ),
                      ),
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
      backgroundColor: const Color(0xFF121824), // 深底色
      appBar: AppBar(
        backgroundColor: const Color(0xFF121824), // 深底色
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.report, color: Color(0xFFE5BA73)),
            SizedBox(width: 8),
            Text('回報', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 打卡區塊
          _buildClockInCard(),
          const SizedBox(height: 24),
          
          // 橫幅式工地名稱與新增回報按鈕
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE5BA73).withOpacity(0.2), // 左側微亮金
                  const Color(0xFF1A2232), // 右側融入卡片底色
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined, color: Color(0xFFE5BA73)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedSiteForClockIn ?? '尚未選擇工地',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_selectedSiteForClockIn == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先在上方選擇工地再新增回報！')));
                      return;
                    }
                    _showAddReportBottomSheet(context, _selectedSiteForClockIn!);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFFE5BA73), shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.black, size: 24),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('近期回報紀錄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              TextButton(onPressed: (){}, child: const Text('查看全部', style: TextStyle(color: Color(0xFFE5BA73)))),
            ],
          ),
          const SizedBox(height: 8),
          // 加入紀錄列表，增加頁面豐富度
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2232),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121824),
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/placeholder.png'), // 可替換為真實圖片
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Icon(Icons.image_outlined, color: Color(0xFF8A94A6)),
                  ),
                  title: const Text('中山區空調保養', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  subtitle: const Text('昨天 17:30 上傳了 4 張照片', style: TextStyle(color: Color(0xFF8A94A6))),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}