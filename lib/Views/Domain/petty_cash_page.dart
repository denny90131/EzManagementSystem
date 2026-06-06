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
      floatingActionButton: FloatingActionButton(
        heroTag: 'petty_cash_fab_tag', // 給予獨立的 heroTag 避免衝突
        onPressed: () {},
        backgroundColor: const Color(0xFFE5BA73), // 琥珀金
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}