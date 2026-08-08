import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
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
  );
  final TextEditingController durationController = TextEditingController();
  final TextEditingController notesController = TextEditingController(); // 總備註
  final TextEditingController projectController = TextEditingController(); // 新增：建案
  final TextEditingController _accessControlNoteController = TextEditingController(); // 新增：門禁/鑰匙備註
  final TextEditingController _parkingSpotNoteController = TextEditingController(); // 新增：停車位備註
  String? _errorMessage; // 新增：用於記錄與顯示錯誤提示
  bool _isSaving = false; // 用於防止重複點擊儲存

  final _formKey = GlobalKey<FormState>(); // 新增：用於表單驗證
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _accessControlImages = [];
  final List<Map<String, dynamic>> _parkingSpotImages = [];
  XFile? _accessControlImageFile; // 新增：門禁/鑰匙圖片
  XFile? _parkingSpotImageFile; // 新增：停車位圖片

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
    _accessControlNoteController.dispose();
    _parkingSpotNoteController.dispose();
    projectController.dispose();
    super.dispose();
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap, bool isRequired = false, List<TextInputFormatter>? inputFormatters}) {
    return _buildCustomTextField(controller: controller, label: label, icon: icon, maxLines: maxLines, keyboardType: keyboardType, readOnly: readOnly, onTap: onTap, isRequired: isRequired, inputFormatters: inputFormatters);
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
    bool isRequired = false, // 新增 isRequired 參數
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters, // 新增：輸入格式化工具
  }) {
    return TextFormField( // Changed from TextField to TextFormField
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      inputFormatters: inputFormatters, // 新增：套用輸入格式
      onTap: onTap,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '請輸入$label';
        }
        // 手機號碼格式驗證 (09開頭，共10碼)
        if (keyboardType == TextInputType.phone && value != null && value.trim().isNotEmpty) {
          final phoneRegExp = RegExp(r'^09\d{8}$');
          if (!phoneRegExp.hasMatch(value.trim())) {
            return '請輸入有效的10碼手機號碼';
          }
        }
        // 數字驗證
        if (keyboardType == TextInputType.number && value != null && value.trim().isNotEmpty) {
          if (num.tryParse(value.trim()) == null) {
            return '請輸入有效的數字';
          }
        }
        return null;
      },
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

  // 新增：下拉式選單輔助元件
  Widget _buildDialogDropdownField(String label, IconData icon, List<String> items, String? value, ValueChanged<String?> onChanged, {bool isRequired = false}) {
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
      validator: isRequired
          ? (val) => (val == null || val.isEmpty) ? '請選擇$label' : null
          : null,
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
    );
  }

  // 顯示圖片來源選擇的 ActionSheet (單張圖片)
  void _showImageSourceActionSheet(BuildContext context, Function(ImageSource) onPickImage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2232),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                title: const Text('拍照', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.of(context).pop(); onPickImage(ImageSource.camera); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE5BA73)),
                title: const Text('從相簿選擇', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.of(context).pop(); onPickImage(ImageSource.gallery); },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // 處理選擇單張圖片
  Future<void> _pickImage(ImageSource source, bool isForAccessControl) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (isForAccessControl) {
            _accessControlImageFile = image;
          } else {
            _parkingSpotImageFile = image;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法存取相機或相簿')));
    }
  }

  // 顯示全螢幕圖片
  void _showFullScreenImage(BuildContext context, XFile imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8), // 半透明黑色背景
          insetPadding: EdgeInsets.zero, // 讓圖片可以佔滿螢幕
          child: Stack(
            children: [
              Center(
                child: Image.file(
                  File(imageFile.path),
                  fit: BoxFit.contain, // 確保圖片完整顯示
                ),
              ),
              Positioned(top: 16, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.of(dialogContext).pop())),
            ],
          ),
        );
      },
    );
  }

  // 建立圖片縮圖作為 TextField 的 suffixIcon
  Widget? _buildImageSuffixIcon(XFile? imageFile, VoidCallback onPickImage, VoidCallback onRemoveImage) {
    if (imageFile != null) {
      return Padding(
        padding: const EdgeInsets.all(4.0), // 增加一些內邊距
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            GestureDetector( // 包裹縮圖，使其可點擊放大
              onTap: () => _showFullScreenImage(context, imageFile),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(File(imageFile.path), width: 40, height: 40, fit: BoxFit.cover), // 縮圖大小
              ),
            ),
            GestureDetector(
              onTap: onRemoveImage,
              child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 0.5)), 
              child: const Icon(Icons.close, color: Colors.white, size: 12)),
            )
          ],
        ),
      );
    } else {
      return IconButton(icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFFE5BA73)), onPressed: onPickImage);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) { // 觸發所有表單欄位的驗證
      setState(() => _errorMessage = '請確認資訊是否填寫完畢');
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

      List<Map<String, String>> sources = [];

      // 處理門禁/鑰匙圖片與備註
      if (_accessControlImageFile != null || _accessControlNoteController.text.trim().isNotEmpty) {
        String? base64Image;
        if (_accessControlImageFile != null) {
          final bytes = await _accessControlImageFile!.readAsBytes();
          base64Image = base64Encode(bytes);
        }
        sources.add({
          "sourceType": "門禁",
          "source": base64Image ?? "",
          "note": _accessControlNoteController.text.trim(),
        });
      }
      // 處理停車位圖片與備註
      if (_parkingSpotImageFile != null || _parkingSpotNoteController.text.trim().isNotEmpty) {
        String? base64Image;
        if (_parkingSpotImageFile != null) {
          final bytes = await _parkingSpotImageFile!.readAsBytes();
          base64Image = base64Encode(bytes);
        }
        sources.add({
          "sourceType": "停車位",
          "source": base64Image ?? "",
          "note": _parkingSpotNoteController.text.trim(),
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
        siteOrderBegeingDate: orderDateController.text.trim().isNotEmpty ? "${orderDateController.text.trim()}T00:00:00" : null,
        siteOrderExecuteTime: int.tryParse(durationController.text.trim()),
        note: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
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
        child: Form( // 包裹 Form 以啟用驗證
          key: _formKey,
          child: Column( // Form widget requires a single child, typically a Column or other layout widget
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogTextField(ownerNameController, '業主名稱', Icons.person_outline, isRequired: true),
                      const SizedBox(height: 12),
                      _buildDialogTextField(ownerPhoneController, '業主手機號碼', Icons.phone_outlined, keyboardType: TextInputType.phone, isRequired: true),
                      const SizedBox(height: 12),
                      _buildDialogTextField(siteNameController, '工地名稱', Icons.work_outline, isRequired: true),
                      const SizedBox(height: 12),
                      _buildDialogTextField(siteAddressController, '工地地址', Icons.location_on_outlined, isRequired: true), // 工地地址
                      const SizedBox(height: 12),
                      _buildDialogTextField(projectController, '建案', Icons.domain_outlined, isRequired: false), // 建案為選填
                      const SizedBox(height: 12),
                      _buildDialogTextField(budgetController, '預算金額', Icons.attach_money_outlined, keyboardType: TextInputType.number, isRequired: true, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
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
                      _buildDialogTextField(durationController, '預計工期 (工作天數)', Icons.timer_outlined, keyboardType: TextInputType.number, isRequired: false, inputFormatters: [FilteringTextInputFormatter.digitsOnly]), // 預計工期為選填
                      
                      // --- 門禁/鑰匙與停車位資訊區 ---
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      // 門禁/鑰匙
                      _buildCustomTextField(
                        controller: _accessControlNoteController,
                        label: '門禁/鑰匙',
                        icon: Icons.vpn_key_outlined,
                        maxLines: 1,
                        suffixIcon: _buildImageSuffixIcon(
                          _accessControlImageFile,
                          () => _showImageSourceActionSheet(context, (source) => _pickImage(source, true)),
                          () => setState(() => _accessControlImageFile = null),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 停車位
                      _buildCustomTextField(
                        controller: _parkingSpotNoteController,
                        label: '停車位',
                        icon: Icons.local_parking_outlined,
                        maxLines: 1,
                        suffixIcon: _buildImageSuffixIcon(_parkingSpotImageFile, () => _showImageSourceActionSheet(context, (source) => _pickImage(source, false)), () => setState(() => _parkingSpotImageFile = null)),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      _buildDialogTextField(notesController, '備註', Icons.note_alt_outlined, maxLines: 3, isRequired: false), // 備註為選填
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18), // Slightly larger icon for error
                    const SizedBox(width: 6),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ],
          ),
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
}