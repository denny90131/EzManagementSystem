import 'package:flutter/material.dart';

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
  final TextEditingController orderDateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String? _errorMessage; // 新增：用於記錄與顯示錯誤提示

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
    notesController.dispose();
    super.dispose();
  }

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
        labelStyle: const TextStyle(color: const Color(0xFF8A94A6)),
        prefixIcon: Icon(icon, color: const Color(0xFF8A94A6)),
        filled: true,
        fillColor: const Color(0xFF121824),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
      ),
    );
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
                    _buildDialogTextField(contractorNameController, '發包人名稱', Icons.handshake_outlined),
                    const SizedBox(height: 12),
                    _buildDialogTextField(contractorPhoneController, '發包人手機', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
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
          onPressed: () {
            if (siteNameController.text.trim().isEmpty) {
              setState(() {
                _errorMessage = '請填寫工地名稱'; // 將錯誤訊息顯示在視窗內
              });
              return;
            }
            setState(() => _errorMessage = null); // 清除錯誤訊息
            // TODO: 這裡可以加入呼叫 API 新增工地的邏輯
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已建立新工地：${siteNameController.text}')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black),
          child: const Text('確認新增', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}