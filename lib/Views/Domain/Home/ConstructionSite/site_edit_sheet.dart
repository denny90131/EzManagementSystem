import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'site_details_model.dart';
import 'custom_widgets.dart';

class SiteEditSheet extends StatefulWidget {
  final SiteDetails initialDetails;
  final SiteAttachment initialAccessControl;
  final SiteAttachment initialParkingSpot;

  const SiteEditSheet({
    super.key,
    required this.initialDetails,
    required this.initialAccessControl,
    required this.initialParkingSpot,
  });

  @override
  State<SiteEditSheet> createState() => _SiteEditSheetState();
}

class _SiteEditSheetState extends State<SiteEditSheet> {
  late final GlobalKey<FormState> _formKey;
  final ImagePicker _picker = ImagePicker();
  late final List<TextEditingController> _controllers;
  late SiteDetails _currentDetails;

  // Local state for attachments during editing
  late TextEditingController _accessControlNoteCtrl;
  late TextEditingController _parkingSpotNoteCtrl;
  XFile? _newAccessControlImage;
  XFile? _newParkingSpotImage;
  bool _isAccessControlImageCleared = false;
  bool _isParkingSpotImageCleared = false;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _currentDetails = widget.initialDetails;
    _controllers = [
      TextEditingController(text: _currentDetails.ownerName),
      TextEditingController(text: _currentDetails.ownerPhone),
      TextEditingController(text: _currentDetails.siteName),
      TextEditingController(text: _currentDetails.siteAddress),
      TextEditingController(text: _currentDetails.project),
      TextEditingController(text: _currentDetails.contractorName),
      TextEditingController(text: _currentDetails.contractorPhone),
      TextEditingController(text: _currentDetails.orderDate),
      TextEditingController(text: _currentDetails.duration),
      TextEditingController(text: _currentDetails.sellingPrice),
      TextEditingController(text: _currentDetails.notes),
    ];
    _accessControlNoteCtrl = TextEditingController(text: widget.initialAccessControl.note);
    _parkingSpotNoteCtrl = TextEditingController(text: widget.initialParkingSpot.note);
  }

  @override
  void dispose() {
    for (var ctrl in _controllers) {
      ctrl.dispose();
    }
    _accessControlNoteCtrl.dispose();
    _parkingSpotNoteCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _currentDetails = widget.initialDetails;
    final initialValues = [
      _currentDetails.ownerName, _currentDetails.ownerPhone, _currentDetails.siteName,
      _currentDetails.siteAddress, _currentDetails.project, _currentDetails.contractorName,
      _currentDetails.contractorPhone, _currentDetails.orderDate, _currentDetails.duration,
      _currentDetails.sellingPrice, _currentDetails.notes
    ];
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].text = initialValues[i];
    }
    _accessControlNoteCtrl.text = widget.initialAccessControl.note ?? '';
    _parkingSpotNoteCtrl.text = widget.initialParkingSpot.note ?? '';
    _newAccessControlImage = null;
    _newParkingSpotImage = null;
    _isAccessControlImageCleared = false;
    _isParkingSpotImageCleared = false;
  }

  Future<void> _saveChanges() async {
    // Create new SiteDetails from controllers
    final updatedDetails = SiteDetails(
      siteUUID: _currentDetails.siteUUID,
      ownerName: _controllers[0].text, ownerPhone: _controllers[1].text,
      siteName: _controllers[2].text, siteAddress: _controllers[3].text,
      project: _controllers[4].text, contractorName: _controllers[5].text,
      contractorPhone: _controllers[6].text, orderDate: _controllers[7].text,
      duration: _controllers[8].text, sellingPrice: _controllers[9].text,
      notes: _controllers[10].text,
    );

    // Create new SiteAttachments
    final updatedAccessControl = SiteAttachment(
      note: _accessControlNoteCtrl.text,
      imageBytes: _newAccessControlImage != null
          ? await _newAccessControlImage!.readAsBytes()
          : (_isAccessControlImageCleared ? null : widget.initialAccessControl.imageBytes),
    );

    final updatedParkingSpot = SiteAttachment(
      note: _parkingSpotNoteCtrl.text,
      imageBytes: _newParkingSpotImage != null
          ? await _newParkingSpotImage!.readAsBytes()
          : (_isParkingSpotImageCleared ? null : widget.initialParkingSpot.imageBytes),
    );

    // Pop with results
    Navigator.pop(context, {
      'details': updatedDetails,
      'accessControl': updatedAccessControl,
      'parkingSpot': updatedParkingSpot,
    });
  }

  // 🚀 新增：顯示全螢幕圖片
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
              Positioned(top: 40, right: 16, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.of(dialogContext).pop())),
            ],
          ),
        );
      },
    );
  }

  // 🚀 新增：建立可編輯狀態下的圖片 suffixIcon (從 details_construction.dart 搬移過來)
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

  @override
  Widget build(BuildContext context) {
    // This would be the full UI of your _showEditSiteDetailsBottomSheet.
    // For brevity, I'm showing a simplified structure.
    // You would migrate the entire UI from the old method here.
    return Padding(
      padding: EdgeInsets.only(top: 60.0, bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A2232),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isEditing ? '編輯工地資料' : '工地詳細資料', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            // Scrollable Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 🚀 補上所有遺漏的欄位
                      buildCustomTextField(controller: _controllers[0], label: '業主名稱', icon: Icons.person_outline, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[1], label: '業主手機號碼', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[2], label: '工地名稱', icon: Icons.work_outline, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[3], label: '工地地址', icon: Icons.location_on_outlined, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[4], label: '建案', icon: Icons.domain_outlined, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[5], label: '發包人名稱', icon: Icons.handshake_outlined, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[6], label: '發包人手機', icon: Icons.phone_android_outlined, keyboardType: TextInputType.phone, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(
                        controller: _controllers[7], 
                        label: '訂單日期', 
                        icon: Icons.calendar_today_outlined, 
                        readOnly: true, // 日期永遠唯讀，透過 onTap 觸發選擇器
                        onTap: _isEditing ? () async {
                          final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (picked != null) setState(() => _controllers[7].text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
                        } : null
                      ),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[8], label: '預計工期 (天)', icon: Icons.timer_outlined, keyboardType: TextInputType.number, readOnly: !_isEditing),
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[9], label: '售價', icon: Icons.sell_outlined, keyboardType: TextInputType.number, readOnly: !_isEditing),
                      
                      // --- 門禁/鑰匙與停車位資訊區 ---
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      // 門禁/鑰匙
                      buildCustomTextField(
                        controller: _accessControlNoteCtrl, 
                        label: '門禁/鑰匙', 
                        icon: Icons.vpn_key_outlined, 
                        readOnly: !_isEditing, 
                        suffixIcon: _isEditing 
                          ? _buildEditableImageSuffixIcon(
                              newImage: _newAccessControlImage, 
                              existingImageBytes: _isAccessControlImageCleared ? null : widget.initialAccessControl.imageBytes, 
                              onPickImage: () async {
                                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                                if (image != null) setState(() => _newAccessControlImage = image);
                              }, 
                              onRemoveImage: () => setState(() { _newAccessControlImage = null; _isAccessControlImageCleared = true; })
                            )
                          : (widget.initialAccessControl.imageBytes != null 
                              ? _buildReadOnlyImageSuffixIcon(widget.initialAccessControl.imageBytes!) 
                              : null)
                      ),
                      const SizedBox(height: 12),
                      // 停車位
                      buildCustomTextField(
                        controller: _parkingSpotNoteCtrl, 
                        label: '停車位', 
                        icon: Icons.local_parking_outlined, 
                        readOnly: !_isEditing, 
                        suffixIcon: _isEditing 
                          ? _buildEditableImageSuffixIcon(
                              newImage: _newParkingSpotImage, 
                              existingImageBytes: _isParkingSpotImageCleared ? null : widget.initialParkingSpot.imageBytes, 
                              onPickImage: () async { 
                                final XFile? image = await _picker.pickImage(source: ImageSource.gallery); 
                                if (image != null) setState(() => _newParkingSpotImage = image); 
                              }, 
                              onRemoveImage: () => setState(() { _newParkingSpotImage = null; _isParkingSpotImageCleared = true; })
                            ) 
                          : (widget.initialParkingSpot.imageBytes != null 
                              ? _buildReadOnlyImageSuffixIcon(widget.initialParkingSpot.imageBytes!) 
                              : null)
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white24),
                      
                      const SizedBox(height: 12),
                      buildCustomTextField(controller: _controllers[10], label: '備註', icon: Icons.note_alt_outlined, maxLines: 3, readOnly: !_isEditing),

                      const SizedBox(height: 24),
                      // Action Buttons
                      if (_isEditing)
                        Row(
                          children: [
                            Expanded(child: OutlinedButton(onPressed: () => setState(() { _resetForm(); _isEditing = false; }), child: const Text('返回'))),
                            const SizedBox(width: 16),
                            Expanded(child: ElevatedButton(onPressed: _saveChanges, child: const Text('儲存變更'))),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: () => setState(() => _isEditing = true),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          child: const Text('編輯資料'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 新增：建立唯讀狀態下的圖片 suffixIcon
  Widget _buildReadOnlyImageSuffixIcon(Uint8List imageBytes) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: () => _showFullScreenImage(context, imageBytes),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(imageBytes, width: 40, height: 40, fit: BoxFit.cover),
        ),
      ),
    );
  }
}