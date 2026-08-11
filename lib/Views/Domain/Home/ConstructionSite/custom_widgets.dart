import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// 一個通用的、帶有專案風格的 TextFormField 元件
Widget buildCustomTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  int maxLines = 1,
  TextInputType? keyboardType,
  bool readOnly = false,
  VoidCallback? onTap,
  bool isRequired = false,
  Widget? suffixIcon,
  List<TextInputFormatter>? inputFormatters,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    readOnly: readOnly,
    inputFormatters: inputFormatters,
    onTap: onTap,
    contextMenuBuilder: readOnly ? (context, editableTextState) => const SizedBox.shrink() : null,
    validator: validator ?? (value) {
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

/// 一個通用的、帶有專案風格的 DropdownButtonFormField 元件
Widget buildCustomDropdownField({
  required String label,
  required IconData icon,
  required List<String> items,
  required String? value,
  required ValueChanged<String?> onChanged,
  bool isRequired = false,
  String? Function(String?)? validator,
}) {
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
    validator: validator ?? (val) => (isRequired && (val == null || val.isEmpty)) ? '請選擇$label' : null,
    items: items.map((String item) {
      return DropdownMenuItem<String>(value: item, child: Text(item));
    }).toList(),
  );
}

/// 顯示圖片來源選擇的 ActionSheet (拍照或從相簿選)
void showImageSourceActionSheet(BuildContext context, Function(ImageSource) onPickImage, {bool allowMultiPick = false}) {
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
              leading: Icon(allowMultiPick ? Icons.photo_library_outlined : Icons.photo_album_outlined, color: Color(0xFFE5BA73)),
              title: Text(allowMultiPick ? '從相簿選擇 (可多選)' : '從相簿選擇', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.of(context).pop(); onPickImage(ImageSource.gallery); },
            ),
          ],
        ),
      );
    },
  );
}

/// Resolves an image provider from various dynamic sources (XFile, Uint8List).
/// Returns a placeholder if the source is invalid.
ImageProvider resolveImageProvider(dynamic img) {
  if (img is XFile) return FileImage(File(img.path));
  if (img is Uint8List) return MemoryImage(img);
  // You can customize your placeholder image asset path here.
  return const AssetImage('assets/images/placeholder.png');
}