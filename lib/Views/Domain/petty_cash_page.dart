import 'package:flutter/material.dart';

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

  // 顯示「新增紀錄」彈出視窗
  void _showAddTransactionDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    final TextEditingController dateController = TextEditingController(
      text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}"
    );
    final TextEditingController notesController = TextEditingController();
    bool isExpense = true; // 預設為「支出」

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
                      const SizedBox(height: 20),
                      _buildDialogTextField(titleController, '項目名稱 / 摘要', Icons.edit_note_outlined),
                      const SizedBox(height: 12),
                      _buildDialogTextField(amountController, '金額', Icons.attach_money_outlined, keyboardType: TextInputType.number),
                      const SizedBox(height: 12),
                      _buildDialogTextField(
                        dateController, 
                        '日期', 
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