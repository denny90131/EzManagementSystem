import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // 🚀 新增：用於 Base64 解碼
import 'dart:ui';
import 'dart:typed_data'; // 🚀 新增：用於 Uint8List
import 'package:image_picker/image_picker.dart';
import 'package:ez_manager/API/construction_api.dart'; // 引入工地 API 服務
import 'custom_widgets.dart'; // 🚀 引入共用元件
import 'site_details_model.dart'; // 🚀 引入新的資料模型
import 'site_edit_sheet.dart'; // 🚀 引入新的編輯頁面
import 'package:file_picker/file_picker.dart';

// --- 案件詳細頁面 (點擊案件卡片時導覽) ---
class CaseDetailPage extends StatefulWidget {
  // 1. 將參數從 siteUUID 改為接收整個 site map
  final Map<String, dynamic> site;

  const CaseDetailPage({super.key, required this.site});

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  int _currentTab = 0; // 0: 會議紀錄, 1: 現況照, 2: 3D模擬圖, 3: 施工圖, 4: 材質表, 5: 設備表
  final ImagePicker _picker = ImagePicker(); // 圖片選擇器器實例

  // 🚀 使用強型別的 Model 取代 Map
  late SiteDetails _siteDetails;
  bool _isLoadingDetails = true; // 新增：追蹤詳細資料是否載入中

  // 🚀 使用強型別的 Model 儲存附件資訊
  SiteAttachment _accessControl = const SiteAttachment.empty();
  SiteAttachment _parkingSpot = const SiteAttachment.empty();

  // 儲存各標籤的圖片清單 (1~5)，現在可以從 API 的 sources 中初始化
  final Map<int, List<dynamic>> _tabImages = {
    1: [], // 現況照
    2: [], // 3D模擬圖
    3: [], // 施工圖
    4: [], // 材質表
    5: [], // 設備表
  };

  @override
  void initState() {
    super.initState();
    // 🚀 使用工廠建構子初始化資料模型
    _siteDetails = SiteDetails.fromInitial(widget.site);

    _fetchSiteDetails(); // 🚀 新增：呼叫新的方法來載入完整的工地詳細資料
  }

// 🚀 新增：從 API 載入完整的工地詳細資料
  Future<void> _fetchSiteDetails() async {
    final siteUUID = widget.site['siteUUID']?.toString();
    if (siteUUID == null) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法取得工地 UUID，請檢查資料來源。')),
      );
      return;
    }

    try {
      final fullSiteData = await ConstructionApiService.getSiteDetail(siteUUID);
      if (!mounted) return;

      if (fullSiteData != null) {
        setState(() {
          // 🚀 使用 fromApi 工廠建構子更新資料，更安全簡潔
          _siteDetails = SiteDetails.fromApi(fullSiteData, fallback: _siteDetails);

          // 處理 sources 資料，將其分配到 _tabImages
          final List<dynamic> sources = fullSiteData['sources'] ?? [];
          for (var source in sources) {
            final String? sourceType = source['sourceType']?.toString();
            final String? sourceData = source['source']?.toString();

            if (sourceType != null && sourceData != null && sourceData.isNotEmpty) {
              try {
                // 🚀 新增：將 Base64 字串解碼為 Uint8List
                final imageBytes = base64Decode(sourceData.split(',').last.replaceAll(RegExp(r'\s+'), ''));
                
                // 🚀 新增：根據 sourceType 分配到對應的 Tab
                switch (sourceType) {
                  case '現況照': _tabImages[1]?.add(imageBytes); break;
                  case '3D模擬圖': _tabImages[2]?.add(imageBytes); break; // 修正：3D模擬圖
                  case '施工圖': _tabImages[3]?.add(imageBytes); break;
                  case '材質表': _tabImages[4]?.add(imageBytes); break;
                  case '設備表': _tabImages[5]?.add(imageBytes); break;
                  case '門禁':
                    _accessControl = SiteAttachment(
                      note: source['note']?.toString(),
                      imageBytes: imageBytes,
                    );
                    break;
                  case '停車位':
                    _parkingSpot = SiteAttachment(
                      note: source['note']?.toString(),
                      imageBytes: imageBytes,
                    );
                    break;
                  default:
                    // 如果有未知的類型，可以選擇性地印出 log 或忽略
                    debugPrint('Unknown source type: $sourceType');
                }
              } catch (e) {
                debugPrint('Failed to decode Base64 image for sourceType "$sourceType": $e');
              }
            }
          }
        }); // setState 結束
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入工地詳細資料失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  // 模擬會議紀錄資料
  final List<Map<String, dynamic>> _mockRecords = [
    {
      'id': '1_pub',
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
      'id': '2_priv',
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

  Widget _buildRecordItem(int originalIndex, Map<String, dynamic> record) {
    final isPrivate = record['isPrivate'] as bool;
    final isDeleted = record['isDeleted'] as bool;

    if (isDeleted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
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
                        final imgProvider = resolveImageProvider(img); // 🚀 使用共用函式
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
      ),
    );
  }

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
    String? baseId;
    Map<String, dynamic>? pubRecord;
    Map<String, dynamic>? privRecord;

    // 如果是編輯模式，利用 baseId 同時找出成對的公開與非公開紀錄
    if (editIndex != null) {
      final existingRecord = _mockRecords[editIndex];
      String currentId = existingRecord['id'];
      if (currentId.endsWith('_pub') || currentId.endsWith('_priv')) {
        baseId = currentId.substring(0, currentId.length - 4);
        int pubIndex = _mockRecords.indexWhere((r) => r['id'] == '${baseId}_pub');
        int privIndex = _mockRecords.indexWhere((r) => r['id'] == '${baseId}_priv');
        if (pubIndex != -1) pubRecord = _mockRecords[pubIndex];
        if (privIndex != -1) privRecord = _mockRecords[privIndex];
      } else {
        baseId = currentId;
        if (existingRecord['isPrivate'] == true) privRecord = existingRecord;
        else pubRecord = existingRecord;
      }
    }

    TextEditingController publicContentController = TextEditingController(text: pubRecord?['content'] ?? '');
    TextEditingController privateContentController = TextEditingController(text: privRecord?['content'] ?? '');
    List<dynamic> publicAttachedImages = List.from(pubRecord?['images'] ?? []);
    List<dynamic> privateAttachedImages = List.from(privRecord?['images'] ?? []);

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
            // 處理附加圖片 (支援多選或拍照)，並透過 isPrivate 參數決定放入哪一個列表
            Future<void> _pickRecordImages(ImageSource source, bool isPrivate) async {
              try {
                if (source == ImageSource.gallery) {
                  final List<XFile> images = await _picker.pickMultiImage();
                  if (images.isNotEmpty) {
                    setModalState(() {
                      if (isPrivate) privateAttachedImages.addAll(images);
                      else publicAttachedImages.addAll(images);
                    });
                  }
                } else {
                  final XFile? image = await _picker.pickImage(source: source);
                  if (image != null) {
                    setModalState(() {
                      if (isPrivate) privateAttachedImages.add(image);
                      else publicAttachedImages.add(image);
                    });
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法存取相機或相簿')));
              }
            }

            void _showImageSource(bool isPrivate) {
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
                          onTap: () { Navigator.pop(ctx2); _pickRecordImages(ImageSource.gallery, isPrivate); },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                          title: const Text('拍照', style: TextStyle(color: Colors.white)),
                          onTap: () { Navigator.pop(ctx2); _pickRecordImages(ImageSource.camera, isPrivate); },
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
                              if (publicContentController.text.trim().isEmpty && privateContentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請至少輸入一項內容')));
                                return;
                              }
                              setState(() {
                                final now = DateTime.now();
                                final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                                
                                String newBaseId = baseId ?? now.millisecondsSinceEpoch.toString();
                                String originalDate = pubRecord?['date'] ?? privRecord?['date'] ?? dateStr;
                                String originalCreator = pubRecord?['creator'] ?? privRecord?['creator'] ?? '當前使用者';
                                
                                int insertIndex = 0;
                                if (editIndex != null) {
                                  insertIndex = _mockRecords.indexWhere((r) => r['id'] == pubRecord?['id'] || r['id'] == privRecord?['id']);
                                  if (insertIndex == -1) insertIndex = 0;
                                  
                                  // 移除原本的紀錄 (將公開與非公開的舊資料一併移除)
                                  _mockRecords.removeWhere((r) => r['id'] == pubRecord?['id'] || r['id'] == privRecord?['id']);
                                }
                                
                                // 插入新的紀錄
                                if (privateContentController.text.trim().isNotEmpty) {
                                  _mockRecords.insert(insertIndex, {
                                    'id': '${newBaseId}_priv',
                                    'date': originalDate,
                                    'creator': originalCreator,
                                    'content': privateContentController.text.trim(),
                                    'isPrivate': true,
                                    'isDeleted': false,
                                    'deletedBy': '',
                                    'deletedAt': '',
                                    'images': List.from(privateAttachedImages),
                                  });
                                }
                                if (publicContentController.text.trim().isNotEmpty) {
                                  _mockRecords.insert(insertIndex, {
                                    'id': '${newBaseId}_pub',
                                    'date': originalDate,
                                    'creator': originalCreator,
                                    'content': publicContentController.text.trim(),
                                    'isPrivate': false,
                                    'isDeleted': false,
                                    'deletedBy': '',
                                    'deletedAt': '',
                                    'images': List.from(publicAttachedImages),
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
                      
                      // 公開紀錄區塊
                      const Row(
                        children: [
                          Icon(Icons.public, color: Color(0xFF8A94A6), size: 18),
                          SizedBox(width: 8),
                          Text('公開紀錄 (業主與所有人可見)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: publicContentController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '請輸入公開的會議或備註內容...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF121824),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                        ),
                      ),
                      
                      // 圖片縮圖列表 (公開)
                      if (publicAttachedImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(publicAttachedImages.length, (i) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: resolveImageProvider(publicAttachedImages[i]), fit: BoxFit.cover)),
                                  ),
                                  Positioned(
                                    top: 0, right: 0,
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => publicAttachedImages.removeAt(i)),
                                      child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                    ),
                                  )
                                ],
                              );
                            }),
                          ),
                        ),
                      const SizedBox(height: 12),
                      
                      OutlinedButton.icon(
                        onPressed: () => _showImageSource(false),
                        icon: const Icon(Icons.image_outlined, color: Color(0xFF8A94A6)),
                        label: const Text('附加公開照片', style: TextStyle(color: Color(0xFF8A94A6))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 0),
                          side: const BorderSide(color: Colors.white12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 非公開紀錄區塊
                      const Row(
                        children: [
                          Icon(Icons.visibility_off_outlined, color: Color(0xFFE5BA73), size: 18),
                          SizedBox(width: 8),
                          Text('非公開紀錄 (僅內部團隊可見)', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: privateContentController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '請輸入內部私下備註內容...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF121824),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                        ),
                      ),
                      
                      // 圖片縮圖列表 (非公開)
                      if (privateAttachedImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(privateAttachedImages.length, (i) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: resolveImageProvider(privateAttachedImages[i]), fit: BoxFit.cover)),
                                  ),
                                  Positioned(
                                    top: 0, right: 0,
                                    child: GestureDetector(
                                      onTap: () => setModalState(() => privateAttachedImages.removeAt(i)),
                                      child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                    ),
                                  )
                                ],
                              );
                            }),
                          ),
                        ),
                      const SizedBox(height: 12),
                      
                      OutlinedButton.icon(
                        onPressed: () => _showImageSource(true),
                        icon: const Icon(Icons.image_outlined, color: Color(0xFF8A94A6)),
                        label: const Text('附加非公開照片', style: TextStyle(color: Color(0xFF8A94A6))),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    // 🚀 改為呼叫共用方法
    showImageSourceActionSheet(context, _pickImage, allowMultiPick: true);
  }

  // 🚀 顯示編輯工地資料的底部彈出視窗 (已重構)
  Future<void> _showEditSiteDetailsBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => SiteEditSheet(
        initialDetails: _siteDetails,
        initialAccessControl: _accessControl,
        initialParkingSpot: _parkingSpot,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _siteDetails = result['details'] as SiteDetails;
        _accessControl = result['accessControl'] as SiteAttachment;
        _parkingSpot = result['parkingSpot'] as SiteAttachment;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('工地資料已更新')));
    }
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
        title: Text(_siteDetails.siteName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        // If details are loading, show the progress indicator. Otherwise, show the content.
        children: _isLoadingDetails
            ? [
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFE5BA73)),
                  ),
                ),
              ]
            : [ // The content to show when loading is complete.
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
                  const SizedBox(width: 24), // 修正
                  _buildTab(5, '設備表'), // 修正
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
                                final imgProvider = resolveImageProvider(_tabImages[_currentTab]![index]);
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
              child: Builder(
                builder: (context) {
                  final publicRecords = _mockRecords.asMap().entries.where((e) => e.value['isPrivate'] == false).toList();
                  final privateRecords = _mockRecords.asMap().entries.where((e) => e.value['isPrivate'] == true).toList();

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // --- 公開紀錄區塊 ---
                          const Row(
                            children: [
                              Icon(Icons.public, color: Color(0xFF8A94A6), size: 20),
                              SizedBox(width: 8),
                              Text('公開紀錄', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (publicRecords.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text('目前尚無公開紀錄', style: TextStyle(color: Color(0xFF8A94A6))),
                              ),
                            )
                          else
                            ...publicRecords.map((e) => _buildRecordItem(e.key, e.value)).toList(),

                          const Divider(height: 48, color: Colors.white12),

                          // --- 非公開紀錄區塊 ---
                          const Row(
                            children: [
                              Icon(Icons.visibility_off_outlined, color: Color(0xFFE5BA73), size: 20),
                              SizedBox(width: 8),
                              Text('非公開紀錄 (內部)', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (privateRecords.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text('目前尚無內部非公開紀錄', style: TextStyle(color: Color(0xFF8A94A6))),
                              ),
                            )
                          else
                            ...privateRecords.map((e) => _buildRecordItem(e.key, e.value)).toList(),
                        ],
                      ),
                    ),
                  );
                },
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

  // 🚀 新增：顯示全螢幕圖片 (用於 Uint8List)
  void _showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(child: InteractiveViewer(child: Image.memory(imageBytes, fit: BoxFit.contain))),
              Positioned(top: 16, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.of(dialogContext).pop())),
            ],
          ),
        );
      },
    );
  }

  // 🚀 新增：建立圖片縮圖作為 TextField 的 suffixIcon
  Widget? _buildImageSuffixIcon(Uint8List? imageBytes, {String? note}) {
    if (imageBytes != null) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(context, imageBytes),
          child: ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(imageBytes, width: 40, height: 40, fit: BoxFit.cover)),
        ),
      );
    }
    return null; // 如果沒有圖片，則不顯示任何東西
  }

  // 🚀 新增：建立可編輯狀態下的圖片 suffixIcon
  Widget _buildEditableImageSuffixIcon({
    XFile? newImage,
    Uint8List? existingImageBytes,
    required VoidCallback onPickImage,
    required VoidCallback onRemoveImage,
  }) {
    ImageProvider? imageProvider;
    if (newImage != null) {
      imageProvider = FileImage(File(newImage.path));
    } else if (existingImageBytes != null) {
      imageProvider = MemoryImage(existingImageBytes);
    }

    if (imageProvider != null) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector(
              onTap: onPickImage, // 點擊縮圖也可以更換圖片
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image(image: imageProvider, width: 40, height: 40, fit: BoxFit.cover),
              ),
            ),
            GestureDetector(
              onTap: onRemoveImage,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 0.5)),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            )
          ],
        ),
      );
    } else {
      return IconButton(icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFE5BA73)), onPressed: onPickImage);
    }
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
          return InteractiveViewer(child: Image(image: resolveImageProvider(img), fit: BoxFit.contain));
        },
      ),
    );
  }
}