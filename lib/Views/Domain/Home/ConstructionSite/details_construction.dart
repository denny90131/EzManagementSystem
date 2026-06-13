import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// --- 案件詳細頁面 (點擊案件卡片時導覽) ---
class CaseDetailPage extends StatefulWidget {
  const CaseDetailPage({super.key});

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  int _currentTab = 0; // 0: 會議紀錄, 1: 現況照, 2: 3D模擬圖, 3: 施工圖, 4: 材質表, 5: 設備表
  int _recordTab = 0; // 0: 公開紀錄, 1: 非公開紀錄
  final ImagePicker _picker = ImagePicker(); // 圖片選擇器器實例

  // 模擬工地詳細資料
  Map<String, dynamic> _siteDetails = {
    'ownerName': '王大明',
    'ownerPhone': '0912-345-678',
    'accessControl': '大門密碼 1234',
    'siteName': '中山區辦公大樓空調維護',
    'siteAddress': '台北市中山區南京東路1段1號',
    'project': '中山世紀辦公大樓',
    'contractorName': '李老闆',
    'contractorPhone': '0987-654-321',
    'constructionItem': '空調工程',
    'budget': '50000',
    'orderDate': '2023-11-20',
    'duration': '5',
    'sellingPrice': '65000',
    'notes': '例行性空調保養，請攜帶A字梯',
  };

  // 儲存各標籤的圖片清單 (1~5)
  final Map<int, List<dynamic>> _tabImages = {
    1: [], // 現況照
    2: [], // 3D模擬圖
    3: [], // 施工圖
    4: [], // 材質表
    5: [], // 設備表
  };

  // 模擬會議紀錄資料
  final List<Map<String, dynamic>> _mockRecords = [
    {
      'id': '1',
      'date': '2023-11-20 14:30',
      'creator': '李老闆 (發包)',
      'content': '現場確認空調管線走線方向，需避開主樑。已與水電師傅確認過。',
      'isPrivate': false,
      'isDeleted': false,
      'deletedBy': '',
      'deletedAt': '',
      'images': [],
    },
    {
      'id': '2',
      'date': '2023-11-19 10:15',
      'creator': '內部備註',
      'content': '業主變更設計，需追加費用約 3,000 元，請盡快報價。',
      'isPrivate': true,
      'isDeleted': false,
      'deletedBy': '',
      'deletedAt': '',
      'images': [],
    },
  ];

  Widget _buildTab(int index, String title) {
    bool isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6),
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          if (isSelected)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE5BA73),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  // 刪除紀錄
  void _deleteRecord(int index) {
    setState(() {
      _mockRecords[index]['isDeleted'] = true;
      _mockRecords[index]['deletedBy'] = '當前使用者';
      _mockRecords[index]['deletedAt'] = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    });
  }

  // 復原紀錄
  void _restoreRecord(int index) {
    setState(() {
      _mockRecords[index]['isDeleted'] = false;
      _mockRecords[index]['deletedBy'] = '';
      _mockRecords[index]['deletedAt'] = '';
    });
  }

  // 開啟全螢幕圖片預覽
  void _openFullScreenGallery(int recordIndex, int initialImageIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGallery(
          images: List.from(_mockRecords[recordIndex]['images']),
          initialIndex: initialImageIndex,
          onImagesUpdated: (updatedImages) {
            setState(() {
              _mockRecords[recordIndex]['images'] = updatedImages;
            });
          },
        ),
      ),
    );
  }

  // 開啟全螢幕圖片預覽 (用於會議紀錄以外的圖片標籤)
  void _openTabFullScreenGallery(int initialImageIndex) {
    final int targetTab = _currentTab;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGallery(
          images: List.from(_tabImages[targetTab] ?? []),
          initialIndex: initialImageIndex,
          onImagesUpdated: (updatedImages) {
            setState(() {
              _tabImages[targetTab] = updatedImages;
            });
          },
        ),
      ),
    );
  }

  // 顯示新增/編輯紀錄的下拉式 BottomSheet
  void _showAddRecordBottomSheet(BuildContext context, {int? editIndex}) {
    final existingRecord = editIndex != null ? _mockRecords[editIndex] : null;
    // 如果是新增，預設隱私狀態跟隨當前切換的 Tab
    bool isPrivate = existingRecord?['isPrivate'] ?? (_recordTab == 1);
    TextEditingController contentController = TextEditingController(text: existingRecord?['content'] ?? '');
    List<dynamic> attachedImages = List.from(existingRecord?['images'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2232),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // 處理附加圖片 (支援多選或拍照)
            Future<void> _pickRecordImages(ImageSource source) async {
              try {
                if (source == ImageSource.gallery) {
                  final List<XFile> images = await _picker.pickMultiImage();
                  if (images.isNotEmpty) {
                    setModalState(() {
                      attachedImages.addAll(images);
                    });
                  }
                } else {
                  final XFile? image = await _picker.pickImage(source: source);
                  if (image != null) {
                    setModalState(() {
                      attachedImages.add(image);
                    });
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法存取相機或相簿')));
              }
            }

            // 顯示圖片來源選擇彈窗
            void _showImageSource() {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1A2232),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (BuildContext ctx2) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE5BA73)),
                          title: const Text('從相簿選擇 (可多選)', style: TextStyle(color: Colors.white)),
                          onTap: () { Navigator.pop(ctx2); _pickRecordImages(ImageSource.gallery); },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                          title: const Text('拍照', style: TextStyle(color: Colors.white)),
                          onTap: () { Navigator.pop(ctx2); _pickRecordImages(ImageSource.camera); },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 頂部拖曳指示條
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(editIndex != null ? '編輯紀錄' : '新增紀錄', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              if (contentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入內容')));
                                return;
                              }
                              setState(() {
                                if (editIndex != null) {
                                  _mockRecords[editIndex]['content'] = contentController.text;
                                  _mockRecords[editIndex]['isPrivate'] = isPrivate;
                                  _mockRecords[editIndex]['images'] = attachedImages;
                                } else {
                                  _mockRecords.insert(0, {
                                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                    'date': '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                    'creator': '當前使用者', // 應替換為真實使用者
                                    'content': contentController.text,
                                    'isPrivate': isPrivate,
                                    'isDeleted': false,
                                    'deletedBy': '',
                                    'deletedAt': '',
                                    'images': attachedImages,
                                  });
                                }
                              });
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('紀錄已儲存')));
                            },
                            child: const Text('確認', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // 隱私設定 (將原本的雙區域改為切換開關，更符合現代設計且利於附加多圖)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(isPrivate ? Icons.visibility_off_outlined : Icons.public, color: isPrivate ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)),
                              const SizedBox(width: 8),
                              Text(isPrivate ? '此紀錄為非公開 (僅內部可見)' : '此紀錄為公開 (所有人可見)', style: TextStyle(color: isPrivate ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6), fontSize: 14)),
                            ],
                          ),
                          Switch(
                            value: isPrivate,
                            activeColor: const Color(0xFFE5BA73),
                            onChanged: (val) {
                              setModalState(() {
                                isPrivate = val;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 內容輸入
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '請輸入會議或備註內容...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF121824),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // 圖片縮圖列表
                      if (attachedImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(attachedImages.length, (i) {
                              final img = attachedImages[i];
                              ImageProvider provider;
                              if (img is XFile) {
                                provider = FileImage(File(img.path));
                              } else {
                                provider = const AssetImage('assets/images/placeholder.png'); // 備用圖
                              }
                              return Stack(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(image: provider, fit: BoxFit.cover),
                                    ),
                                  ),
                                  // 移除圖片按鈕
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          attachedImages.removeAt(i);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            }),
                          ),
                        ),

                      // 附加圖片按鈕
                      OutlinedButton.icon(
                        onPressed: _showImageSource,
                        icon: const Icon(Icons.image_outlined, color: Color(0xFF8A94A6)),
                        label: const Text('附加圖片', style: TextStyle(color: Color(0xFF8A94A6))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 0),
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  // 處理選擇圖片 (支援多選或拍照)
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          setState(() => _tabImages[_currentTab]?.addAll(images));
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          setState(() => _tabImages[_currentTab]?.add(image));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法存取相機或相簿，請確認權限。')));
    }
  }

  // 顯示圖片來源選擇的底部彈出選單
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2232),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE5BA73)),
                title: const Text('從相簿選擇 (可多選)', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                title: const Text('拍照', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
              ),
            ],
          ),
        );
      },
    );
  }

  // 建立表單輸入框的輔助元件
  Widget _buildEditTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) {
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
  Widget _buildEditDropdownField(String label, IconData icon, List<String> items, String? value, ValueChanged<String?>? onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      dropdownColor: const Color(0xFF1A2232),
      onChanged: onChanged,
      icon: onChanged == null ? const SizedBox.shrink() : null,
      style: TextStyle(color: onChanged == null ? Colors.white70 : Colors.white),
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

  // 顯示編輯工地資料的底部彈出視窗
  void _showEditSiteDetailsBottomSheet() {
    bool isEditing = false;
    final ownerNameCtrl = TextEditingController(text: _siteDetails['ownerName']);
    final ownerPhoneCtrl = TextEditingController(text: _siteDetails['ownerPhone']);
    final accessControlCtrl = TextEditingController(text: _siteDetails['accessControl']);
    final siteNameCtrl = TextEditingController(text: _siteDetails['siteName']);
    final siteAddressCtrl = TextEditingController(text: _siteDetails['siteAddress']);
    final projectCtrl = TextEditingController(text: _siteDetails['project']);
    final contractorNameCtrl = TextEditingController(text: _siteDetails['contractorName']);
    final contractorPhoneCtrl = TextEditingController(text: _siteDetails['contractorPhone']);
    final budgetCtrl = TextEditingController(text: _siteDetails['budget']);
    final orderDateCtrl = TextEditingController(text: _siteDetails['orderDate']);
    final durationCtrl = TextEditingController(text: _siteDetails['duration']);
    final sellingPriceCtrl = TextEditingController(text: _siteDetails['sellingPrice']);
    final notesCtrl = TextEditingController(text: _siteDetails['notes']);
    String? selectedConstructionItem = _siteDetails['constructionItem'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 改為透明以自訂頂部間距
      elevation: 0,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              // 增加 top: 60 避免畫面太貼齊上方
              padding: EdgeInsets.only(top: 60.0, bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A2232),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 固定在頂部的標題列與關閉按鈕
                    Padding(
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 16.0, bottom: 8.0),
                      child: Column(
                        children: [
                          // 頂部拖曳指示條
                          Center(
                            child: Container(
                              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isEditing ? '編輯工地資料' : '工地詳細資料', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 讓內部表單可滾動
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                        child: Column(
                          children: [
                            _buildEditTextField(ownerNameCtrl, '業主名稱', Icons.person_outline, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(ownerPhoneCtrl, '業主手機號碼', Icons.phone_outlined, keyboardType: TextInputType.phone, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(accessControlCtrl, '門禁', Icons.vpn_key_outlined, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(siteNameCtrl, '工地名稱', Icons.work_outline, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(siteAddressCtrl, '工地地址', Icons.location_on_outlined, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(projectCtrl, '建案', Icons.domain_outlined, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(contractorNameCtrl, '發包人名稱', Icons.handshake_outlined, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(contractorPhoneCtrl, '發包人手機', Icons.phone_android_outlined, keyboardType: TextInputType.phone, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditDropdownField(
                              '施工項目', Icons.category_outlined, 
                              ['水電工程', '木作工程', '泥作工程', '油漆工程', '空調工程', '清潔工程', '其他'], 
                              selectedConstructionItem, isEditing ? (val) => setModalState(() => selectedConstructionItem = val) : null
                            ),
                            const SizedBox(height: 12),
                            _buildEditTextField(budgetCtrl, '預算金額', Icons.attach_money_outlined, keyboardType: TextInputType.number, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(orderDateCtrl, '訂單日期', Icons.calendar_today_outlined, readOnly: true, onTap: isEditing ? () async {
                              final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                              if (picked != null) setModalState(() => orderDateCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                            } : null),
                            const SizedBox(height: 12),
                            _buildEditTextField(durationCtrl, '預計工期 (天)', Icons.timer_outlined, keyboardType: TextInputType.number, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(sellingPriceCtrl, '售價', Icons.sell_outlined, keyboardType: TextInputType.number, readOnly: !isEditing),
                            const SizedBox(height: 12),
                            _buildEditTextField(notesCtrl, '備註', Icons.note_alt_outlined, maxLines: 3, readOnly: !isEditing),
                            const SizedBox(height: 24),
                            if (isEditing)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // 返回檢視模式並還原資料
                                        ownerNameCtrl.text = _siteDetails['ownerName'];
                                        ownerPhoneCtrl.text = _siteDetails['ownerPhone'];
                                        accessControlCtrl.text = _siteDetails['accessControl'];
                                        siteNameCtrl.text = _siteDetails['siteName'];
                                        siteAddressCtrl.text = _siteDetails['siteAddress'];
                                        projectCtrl.text = _siteDetails['project'];
                                        contractorNameCtrl.text = _siteDetails['contractorName'];
                                        contractorPhoneCtrl.text = _siteDetails['contractorPhone'];
                                        budgetCtrl.text = _siteDetails['budget'];
                                        orderDateCtrl.text = _siteDetails['orderDate'];
                                        durationCtrl.text = _siteDetails['duration'];
                                        sellingPriceCtrl.text = _siteDetails['sellingPrice'];
                                        notesCtrl.text = _siteDetails['notes'];
                                        setModalState(() {
                                          selectedConstructionItem = _siteDetails['constructionItem'];
                                          isEditing = false;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF8A94A6),
                                        side: const BorderSide(color: Color(0xFF8A94A6)),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('返回', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() => _siteDetails = { 'ownerName': ownerNameCtrl.text, 'ownerPhone': ownerPhoneCtrl.text, 'accessControl': accessControlCtrl.text, 'siteName': siteNameCtrl.text, 'siteAddress': siteAddressCtrl.text, 'project': projectCtrl.text, 'contractorName': contractorNameCtrl.text, 'contractorPhone': contractorPhoneCtrl.text, 'constructionItem': selectedConstructionItem, 'budget': budgetCtrl.text, 'orderDate': orderDateCtrl.text, 'duration': durationCtrl.text, 'sellingPrice': sellingPriceCtrl.text, 'notes': notesCtrl.text });
                                        setModalState(() => isEditing = false);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('工地資料已更新')));
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      child: const Text('儲存變更', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ),
                                ],
                              )
                            else
                              ElevatedButton(
                                onPressed: () {
                                  setModalState(() => isEditing = true);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text('編輯資料', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  // 處理選擇文件 (使用 file_picker 套件)
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已選擇檔案：${result.files.single.name}，準備上傳...')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法存取檔案，請確認權限。')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 深色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF121824), // 深色背景
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('工地資料', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.domain_outlined, color: Color(0xFFE5BA73)),
            tooltip: '工地詳細資料',
            onPressed: _showEditSiteDetailsBottomSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 2. 專案資料分類標籤
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildTab(0, '會議紀錄'),
                  const SizedBox(width: 24),
                  _buildTab(1, '現況照'),
                  const SizedBox(width: 24),
                  _buildTab(2, '3D模擬圖'),
                  const SizedBox(width: 24),
                  _buildTab(3, '施工圖'),
                  const SizedBox(width: 24),
                  _buildTab(4, '材質表'),
                  const SizedBox(width: 24),
                  _buildTab(5, '設備表'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 3. 照片網格內容區
          if (_currentTab >= 1)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    Expanded(
                      child: (_tabImages[_currentTab] == null || _tabImages[_currentTab]!.isEmpty)
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 48, color: Color(0xFF8A94A6)),
                                  SizedBox(height: 16),
                                  Text('目前尚無圖片，請點擊下方按鈕新增', style: TextStyle(color: Color(0xFF8A94A6))),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 9 / 16, // 16:9 垂直長方型
                              ),
                              itemCount: _tabImages[_currentTab]!.length,
                              itemBuilder: (context, index) {
                                final img = _tabImages[_currentTab]![index];
                                ImageProvider imgProvider;
                                if (img is XFile) {
                                  imgProvider = FileImage(File(img.path));
                                } else {
                                  imgProvider = const AssetImage('assets/images/placeholder.png');
                                }
                                return GestureDetector(
                                  onTap: () => _openTabFullScreenGallery(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121824),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                      image: DecorationImage(image: imgProvider, fit: BoxFit.cover),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // 統計與下載操作 Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2232),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('共 ${_tabImages[_currentTab]?.length ?? 0} 張圖片', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14)),
                          OutlinedButton(
                            onPressed: (_tabImages[_currentTab] == null || _tabImages[_currentTab]!.isEmpty) ? null : () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('準備打包下載...')));
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: (_tabImages[_currentTab] == null || _tabImages[_currentTab]!.isEmpty) ? Colors.white24 : Colors.white,
                              foregroundColor: const Color(0xFF1A2232),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('下載全部圖片', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 4. 會議紀錄區 (Tab 0)
          if (_currentTab == 0)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  // --- 公開/非公開 切換區塊 ---
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _recordTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _recordTab == 0 ? const Color(0xFFE5BA73).withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('公開紀錄', style: TextStyle(color: _recordTab == 0 ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _recordTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _recordTab == 1 ? const Color(0xFFE5BA73).withOpacity(0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 16, color: _recordTab == 1 ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)),
                                  const SizedBox(width: 4),
                                  Text('非公開 (內部)', style: TextStyle(color: _recordTab == 1 ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  
                  // --- 紀錄清單 ---
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        // 根據 _recordTab 過濾，並保留原始 index
                        final filteredRecords = _mockRecords.asMap().entries.where((entry) {
                          final isPrivate = entry.value['isPrivate'] == true;
                          return _recordTab == 0 ? !isPrivate : isPrivate;
                        }).toList();

                        if (filteredRecords.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 48, color: const Color(0xFF8A94A6).withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(_recordTab == 0 ? '目前尚無公開紀錄' : '目前尚無內部非公開紀錄', style: const TextStyle(color: Color(0xFF8A94A6))),
                              ],
                            ),
                          );
                        }

                        return ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredRecords.length,
                            separatorBuilder: (context, index) => const Divider(height: 32, color: Colors.white12),
                            itemBuilder: (context, index) {
                              final originalIndex = filteredRecords[index].key;
                              final record = filteredRecords[index].value;
                              final isPrivate = record['isPrivate'] as bool;
                              final isDeleted = record['isDeleted'] as bool;

                          if (isDeleted) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline, color: Color(0xFF8A94A6), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('此紀錄已於 ${record['deletedAt']} 由 ${record['deletedBy']} 刪除', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13))),
                                  TextButton(
                                    onPressed: () => _restoreRecord(originalIndex),
                                    child: const Text('復原', style: TextStyle(color: Color(0xFFE5BA73))),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isPrivate ? Icons.visibility_off_outlined : Icons.person_outline, 
                                        size: 16, 
                                        color: isPrivate ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        record['creator'], 
                                        style: TextStyle(
                                          color: isPrivate ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6), 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(record['date'], style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                                      const SizedBox(width: 4),
                                      // 編輯/刪除彈出選單
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Color(0xFF8A94A6), size: 18),
                                        color: const Color(0xFF1E2532),
                                        offset: const Offset(0, 30),
                                        onSelected: (val) {
                                          if (val == 'edit') _showAddRecordBottomSheet(context, editIndex: originalIndex);
                                          else if (val == 'delete') _deleteRecord(originalIndex);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Text('編輯', style: TextStyle(color: Colors.white))),
                                          const PopupMenuItem(value: 'delete', child: Text('刪除', style: TextStyle(color: Colors.redAccent))),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isPrivate ? const Color(0xFFE5BA73).withOpacity(0.1) : const Color(0xFF121824),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isPrivate ? Border.all(color: const Color(0xFFE5BA73).withOpacity(0.3)) : Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(record['content'], style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
                                    // 顯示紀錄夾帶的圖片縮圖
                                    if (record['images'] != null && (record['images'] as List).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate((record['images'] as List).length, (imgIndex) {
                                            final img = record['images'][imgIndex];
                                            ImageProvider imgProvider;
                                            if (img is XFile) {
                                              imgProvider = FileImage(File(img.path));
                                            } else {
                                              imgProvider = const AssetImage('assets/images/placeholder.png'); // 備用示意圖
                                            }
                                            return GestureDetector(
                                              onTap: () => _openFullScreenGallery(originalIndex, imgIndex), // 點擊開啟全螢幕
                                              child: Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: imgProvider, fit: BoxFit.cover)),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                  ],
                                )
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
        ],
      ),
      // 4. 底部固定操作欄
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2232), // 深色卡片
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: _currentTab == 0
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddRecordBottomSheet(context),
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text('新增紀錄', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5BA73),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showImageSourceActionSheet(context),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('上傳圖片', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF121824),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE5BA73)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('上傳文件', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5BA73), // 金色按鈕
                        foregroundColor: Colors.black, // 黑字
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

// --- 全螢幕圖片預覽元件 ---
class FullScreenGallery extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;
  final Function(List<dynamic>) onImagesUpdated;

  const FullScreenGallery({super.key, required this.images, required this.initialIndex, required this.onImagesUpdated});

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late List<dynamic> _currentImages;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentImages = List.from(widget.images);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _deleteCurrentImage() {
    setState(() {
      _currentImages.removeAt(_currentIndex);
      widget.onImagesUpdated(_currentImages);
      if (_currentImages.isEmpty) {
        Navigator.pop(context);
      } else if (_currentIndex >= _currentImages.length) {
        _currentIndex = _currentImages.length - 1;
      }
    });
  }

  void _downloadCurrentImage() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('圖片已開始下載...')));
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImages.isEmpty) return const Scaffold(backgroundColor: Colors.black);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1} / ${_currentImages.length}', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.download), tooltip: '下載圖片', onPressed: _downloadCurrentImage),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: '刪除圖片', onPressed: _deleteCurrentImage),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _currentImages.length,
        onPageChanged: (idx) => setState(() => _currentIndex = idx),
        itemBuilder: (context, index) {
          final img = _currentImages[index];
          ImageProvider provider = img is XFile ? FileImage(File(img.path)) : const AssetImage('assets/images/placeholder.png') as ImageProvider;
          return InteractiveViewer(child: Image(image: provider, fit: BoxFit.contain));
        },
      ),
    );
  }
}