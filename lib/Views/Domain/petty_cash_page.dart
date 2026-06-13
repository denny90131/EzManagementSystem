import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class PettyCashPage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const PettyCashPage({super.key, this.userData});

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

  // 彈出視窗專用的輸入框元件 (與 HomePage 風格一致)
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

  // 建立選項切換的輔助元件 (平行擺放用)
  Widget _buildSegmentedControl(String label, List<String> options, String currentValue, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: opt == options.last ? 0 : 8.0),
              child: ChoiceChip(
                label: Center(child: Text(opt, style: TextStyle(fontSize: 12, color: currentValue == opt ? Colors.black : Colors.white))),
                selected: currentValue == opt,
                selectedColor: const Color(0xFFE5BA73),
                backgroundColor: const Color(0xFF121824),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: currentValue == opt ? const Color(0xFFE5BA73) : Colors.white12)),
                showCheckmark: false,
                onSelected: (val) { if (val) onChanged(opt); },
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // 顯示「新增紀錄」彈出視窗
  void _showAddTransactionDialog(BuildContext context) {
    final ImagePicker picker = ImagePicker();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dateController = TextEditingController(
      text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
    );
    final TextEditingController vendorController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    bool isExpense = true; // 預設為「支出」
    String? selectedPaymentMethod;
    String? selectedTrade;
    String taxType = '不拿發票';
    String? selectedHandler;
    String payerType = '公司';
    List<dynamic> attachedFiles = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A2232), // 深色卡片背景
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('新增紀錄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 支出與收入切換按鈕
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => isExpense = true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isExpense ? Colors.redAccent : const Color(0xFF121824),
                                foregroundColor: isExpense ? Colors.white : const Color(0xFF8A94A6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('支出', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => isExpense = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !isExpense ? Colors.greenAccent : const Color(0xFF121824),
                                foregroundColor: !isExpense ? Colors.black : const Color(0xFF8A94A6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('收入', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(
                        dateController, 
                        '付款日期', 
                        Icons.calendar_today_outlined, 
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
                        }
                      ),
                      const SizedBox(height: 12),
                      _buildDialogDropdownField('支付方式', Icons.payment_outlined, ['現金', '電匯/簽帳'], selectedPaymentMethod, (val) => setState(() => selectedPaymentMethod = val)),
                      const SizedBox(height: 12),
                      _buildDialogTextField(vendorController, '購買對象 (廠商/店名)', Icons.storefront_outlined),
                      const SizedBox(height: 12),
                      _buildDialogDropdownField('工種', Icons.category_outlined, ['泥作', '木作', '水電', '油漆', '空調', '清潔', '其他'], selectedTrade, (val) => setState(() => selectedTrade = val)),
                      const SizedBox(height: 12),
                      _buildDialogTextField(titleController, '項目名稱', Icons.edit_note_outlined),
                      const SizedBox(height: 12),
                      _buildDialogTextField(amountController, '金額', Icons.attach_money_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildSegmentedControl('稅務選項', ['稅內', '稅外', '不拿發票'], taxType, (val) => setState(() => taxType = val)),
                      const SizedBox(height: 16),
                      _buildDialogDropdownField('經手人', Icons.person_outline, ['經手人A', '經手人B', '老闆'], selectedHandler, (val) => setState(() => selectedHandler = val)),
                      const SizedBox(height: 16),
                      _buildSegmentedControl('誰付錢', ['公司', '廠商'], payerType, (val) => setState(() => payerType = val)),
                      const SizedBox(height: 16),
                      
                      // 憑證上傳區塊
                      const Align(alignment: Alignment.centerLeft, child: Text('上傳憑證 (照片/文件)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      if (attachedFiles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(attachedFiles.length, (i) {
                              final file = attachedFiles[i];
                              bool isImage = false;
                              String? path;
                              
                              if (file is XFile) {
                                isImage = true;
                                path = file.path;
                              } else if (file is PlatformFile) {
                                isImage = ['png', 'jpg', 'jpeg'].contains(file.extension?.toLowerCase());
                                path = file.path;
                              }

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF121824),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white12),
                                      image: isImage && path != null ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover) : null,
                                    ),
                                    child: !isImage ? const Icon(Icons.insert_drive_file, color: Color(0xFF8A94A6)) : null,
                                  ),
                                  Positioned(
                                    top: -6, right: -6,
                                    child: GestureDetector(
                                      onTap: () => setState(() => attachedFiles.removeAt(i)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2), 
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), 
                                        child: const Icon(Icons.close, color: Colors.white, size: 14)
                                      ),
                                    ),
                                  )
                                ],
                              );
                            }),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: const Color(0xFF1A2232),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                  builder: (ctx2) => SafeArea(
                                    child: Wrap(
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE5BA73)),
                                          title: const Text('從相簿選擇', style: TextStyle(color: Colors.white)),
                                          onTap: () async {
                                            Navigator.pop(ctx2);
                                            final images = await picker.pickMultiImage();
                                            if (images.isNotEmpty) setState(() => attachedFiles.addAll(images));
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                                          title: const Text('拍照', style: TextStyle(color: Colors.white)),
                                          onTap: () async {
                                            Navigator.pop(ctx2);
                                            final image = await picker.pickImage(source: ImageSource.camera);
                                            if (image != null) setState(() => attachedFiles.add(image));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF8A94A6), size: 16),
                              label: const Text('照片', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white12), padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await FilePicker.platform.pickFiles();
                                if (result != null) setState(() => attachedFiles.addAll(result.files));
                              },
                              icon: const Icon(Icons.upload_file_outlined, color: Color(0xFF8A94A6), size: 16),
                              label: const Text('文件', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white12), padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDialogTextField(notesController, '備註 (選填)', Icons.note_alt_outlined, maxLines: 3),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Color(0xFF8A94A6))),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: 這裡之後可以加入呼叫 API 的邏輯
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已新增一筆${isExpense ? '支出' : '收入'}：${titleController.text}')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73), foregroundColor: Colors.black),
                  child: const Text('儲存紀錄', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
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
            Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFE5BA73)),
            SizedBox(width: 8),
            Text('零用金', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('現場採買與核銷狀態', style: TextStyle(fontSize: 16, color: Color(0xFF8A94A6), fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          _buildSummaryRow('可用餘額', r'$18,400', Icons.account_balance_wallet_outlined),
          _buildSummaryRow('待核銷', r'$4,260', Icons.receipt_long_outlined),
          _buildSummaryRow('今日支出', r'$1,120', Icons.trending_down),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('近期交易紀錄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              TextButton(onPressed: (){}, child: const Text('查看全部', style: TextStyle(color: Color(0xFFE5BA73)))),
            ],
          ),
          const SizedBox(height: 8),
          // 加入近期交易列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
            itemBuilder: (context, index) {
              final isExpense = index != 2; // 模擬資料，第3筆為入帳
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isExpense ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
                  child: Icon(
                    isExpense ? Icons.arrow_outward : Icons.arrow_downward,
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
                title: Text(isExpense ? '五金行材料採買' : '公司撥款', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text('2023-11-${20 - index}', style: const TextStyle(color: Color(0xFF8A94A6))),
                trailing: Text(
                  isExpense ? r'-$450' : r'+$5,000',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // 抬高按鈕，避免被底部的導航列(毛玻璃)遮擋而無法點擊
        child: FloatingActionButton(
          heroTag: 'petty_cash_fab_tag', // 給予獨立的 heroTag 避免衝突
          onPressed: () => _showAddTransactionDialog(context),
          backgroundColor: const Color(0xFFE5BA73), // 琥珀金
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }
}