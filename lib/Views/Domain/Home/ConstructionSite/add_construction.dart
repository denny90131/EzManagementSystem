import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../API/construction_api.dart';

class AddConstructionDialog extends StatefulWidget {
  const AddConstructionDialog({super.key});

  // 提供一個靜態方法方便外部直接呼叫開啟對話框
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AddConstructionDialog(),
    );
  }

  @override
  State<AddConstructionDialog> createState() => _AddConstructionDialogState();
}

class _AddConstructionDialogState extends State<AddConstructionDialog> {
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController ownerPhoneController = TextEditingController();
  final TextEditingController siteNameController = TextEditingController();
  final TextEditingController siteAddressController = TextEditingController();
  final TextEditingController contractorNameController = TextEditingController();
  final TextEditingController contractorPhoneController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController orderDateController = TextEditingController(
    text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
  );
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController projectController = TextEditingController(); // 新增：建案
  final TextEditingController accessControlController = TextEditingController(); // 新增：門禁
  final TextEditingController parkingSpotController = TextEditingController(); // 新增：停車位
  final TextEditingController sellingPriceController = TextEditingController(); // 新增：售價
  String? _errorMessage; // 新增：用於記錄與顯示錯誤提示
  bool _isSaving = false;
  final TextEditingController constructionItemController = TextEditingController(); // 改為使用控制器

  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _accessControlImages = [];
  final List<Map<String, dynamic>> _parkingSpotImages = [];

  @override
  void dispose() {
    ownerNameController.dispose();
    ownerPhoneController.dispose();
    siteNameController.dispose();
    siteAddressController.dispose();
    contractorNameController.dispose();
    contractorPhoneController.dispose();
    budgetController.dispose();
    orderDateController.dispose();
    durationController.dispose();
    notesController.dispose();
    projectController.dispose();
    accessControlController.dispose();
    parkingSpotController.dispose();
    sellingPriceController.dispose();
    constructionItemController.dispose();
    for (var imgData in _accessControlImages) {
      (imgData['controller'] as TextEditingController).dispose();
    }
    for (var imgData in _parkingSpotImages) {
      (imgData['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap}) {
    return _buildCustomTextField(controller: controller, label: label, icon: icon, maxLines: maxLines, keyboardType: keyboardType, readOnly: readOnly, onTap: onTap);
  }

  // 建立一個更通用的 TextField Builder，方便加入 suffixIcon
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
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
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF121824),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
      ),
    );
  }

  // 顯示圖片來源選擇的 ActionSheet
  void _showImageSourceActionSheet(BuildContext context, Function(ImageSource) onPick) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2232),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE5BA73)),
                title: const Text('從相簿選擇 (可多選)', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.of(context).pop(); onPick(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                title: const Text('拍照', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.of(context).pop(); onPick(ImageSource.camera); },
              ),
            ],
          ),
        );
      },
    );
  }

  // 處理選擇圖片
  Future<void> _pickImages(ImageSource source, bool isForAccessControl) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          final newImages = images.map((file) => {'file': file, 'controller': TextEditingController()}).toList();
          setState(() {
            if (isForAccessControl) {
              _accessControlImages.addAll(newImages);
            } else {
              _parkingSpotImages.addAll(newImages);
            }
          });
        }
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          final newImage = {'file': image, 'controller': TextEditingController()};
          setState(() {
            if (isForAccessControl) {
              _accessControlImages.add(newImage);
            } else {
              _parkingSpotImages.add(newImage);
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法存取相機或相簿')));
    }
  }

  Future<void> _submit() async {
    if (siteNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '請填寫工地名稱');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final teamUUID = prefs.getString('active_team_uuid');
      final memberUUID = prefs.getString('user_id');

      if (teamUUID == null || memberUUID == null) {
        setState(() => _errorMessage = '無法取得團隊或使用者資訊，請重新登入');
        return;
      }

      // 處理圖片與備註
      List<Map<String, String>> sources = [];
      for (var imgData in _accessControlImages) {
        final file = imgData['file'] as XFile;
        final controller = imgData['controller'] as TextEditingController;
        final bytes = await file.readAsBytes();
        sources.add({
          "sourceType": "image",
          "source": base64Encode(bytes),
          "note": "門禁照片: ${controller.text.trim()}",
        });
      }
      for (var imgData in _parkingSpotImages) {
        final file = imgData['file'] as XFile;
        final controller = imgData['controller'] as TextEditingController;
        final bytes = await file.readAsBytes();
        sources.add({
          "sourceType": "image",
          "source": base64Encode(bytes),
          "note": "停車位照片: ${controller.text.trim()}",
        });
      }

      final (errorMessage, data) = await ConstructionApiService.insertNewSite(
        teamUUID: teamUUID,
        uploadMemberUUID: memberUUID,
        siteName: siteNameController.text.trim(),
        siteAddress: siteAddressController.text.trim(),
        siteOwner: ownerNameController.text.trim(),
        siteOwnerPhoneNumber: ownerPhoneController.text.trim(),
        siteClient: contractorNameController.text.trim(),
        siteClientPhoneNumber: contractorPhoneController.text.trim(),
        price: int.tryParse(budgetController.text.trim()),
        siteOrderBegeingDate: orderDateController.text.isNotEmpty ? "${orderDateController.text.trim()}T00:00:00" : null,
        siteOrderExecuteTime: int.tryParse(durationController.text.trim()),
        siteProperty: constructionItemController.text.trim(),
        note: notesController.text.trim(),
        sources: sources.isEmpty ? null : sources,
      );

      if (!mounted) return;

      if (errorMessage == null) {
        Navigator.pop(context, true); // 回傳 true 代表新增成功
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已建立新工地：${siteNameController.text}')));
      } else {
        setState(() => _errorMessage = errorMessage);
      }
    } catch (e) {
      setState(() => _errorMessage = '發生未預期的錯誤: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2232), // 深色卡片背景
      title: const Text('新增工地', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialogTextField(ownerNameController, '業主名稱', Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildDialogTextField(ownerPhoneController, '業主手機號碼', Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildDialogTextField(siteNameController, '工地名稱', Icons.work_outline),
                    const SizedBox(height: 12),
                    _buildDialogTextField(siteAddressController, '工地地址', Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _buildCustomTextField(
                      controller: accessControlController,
                      label: '門禁/鑰匙',
                      icon: Icons.vpn_key_outlined,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFE5BA73)),
                        onPressed: () => _showImageSourceActionSheet(context, (source) => _pickImages(source, true)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_accessControlImages.isNotEmpty)
                      _buildImageThumbnails(_accessControlImages, (index) => setState(() => _accessControlImages.removeAt(index))),
                    const SizedBox(height: 12),
                    _buildCustomTextField(
                      controller: parkingSpotController,
                      label: '停車位',
                      icon: Icons.local_parking_outlined,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFE5BA73)),
                        onPressed: () => _showImageSourceActionSheet(context, (source) => _pickImages(source, false)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_parkingSpotImages.isNotEmpty)
                      _buildImageThumbnails(_parkingSpotImages, (index) => setState(() => _parkingSpotImages.removeAt(index))),
                    const SizedBox(height: 12),
                    _buildDialogTextField(projectController, '建案', Icons.domain_outlined),
                    const SizedBox(height: 12),
                    _buildDialogTextField(contractorNameController, '發包人名稱', Icons.handshake_outlined),
                    const SizedBox(height: 12),
                    _buildDialogTextField(contractorPhoneController, '發包人手機', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildDialogTextField(constructionItemController, '施工項目', Icons.category_outlined),
                    const SizedBox(height: 12),
                    _buildDialogTextField(sellingPriceController, '售價', Icons.sell_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildDialogTextField(budgetController, '預算金額', Icons.attach_money_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildDialogTextField(orderDateController, '訂單日期', Icons.calendar_today_outlined, readOnly: true, onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          orderDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        });
                      }
                    }),
                    const SizedBox(height: 12),
                    _buildDialogTextField(durationController, '預計工期 (工作天數)', Icons.timer_outlined, keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildDialogTextField(notesController, '備註', Icons.note_alt_outlined, maxLines: 3),
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
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black),
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('確認新增', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildImageThumbnails(List<Map<String, dynamic>> images, Function(int) onRemove) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(images.length, (i) {
        final imageFile = images[i]['file'] as XFile;
        final controller = images[i]['controller'] as TextEditingController;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: FileImage(File(imageFile.path)), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: '備註...',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -8, right: -8,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 14)),
              ),
            )
          ],
        );
      }),
    );
  }
}