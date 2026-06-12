import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WoodUsageCalculatorPage extends StatefulWidget {
  const WoodUsageCalculatorPage({super.key});

  @override
  State<WoodUsageCalculatorPage> createState() => _WoodUsageCalculatorPageState();
}

class _WoodUsageCalculatorPageState extends State<WoodUsageCalculatorPage> {
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _thicknessCtrl = TextEditingController();
  
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _lossCtrl = TextEditingController(text: '10');

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _thicknessCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _lossCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {}); // 觸發畫面重繪，數值會在 build 中即時計算
  }

  String _format(double val) {
    if (val == 0) return '0';
    String s = val.toStringAsFixed(4);
    s = s.replaceAll(RegExp(r'0*$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s.isEmpty ? '0' : s;
  }

  String _formatCurrency(double val) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    double l = double.tryParse(_lengthCtrl.text) ?? 0.0;
    double w = double.tryParse(_widthCtrl.text) ?? 0.0;
    double t = double.tryParse(_thicknessCtrl.text) ?? 0.0;
    
    double q = double.tryParse(_qtyCtrl.text) ?? 1.0;
    double price = double.tryParse(_priceCtrl.text) ?? 0.0;
    double loss = double.tryParse(_lossCtrl.text) ?? 10.0;

    // 依據需求：才積 = (長 cm × 寬 cm × 厚 cm) / 2779.313
    double singleTsai = (l * w * t) / 2779.313;
    double totalTsai = singleTsai * q;
    double totalTsaiWithLoss = totalTsai * (1 + loss / 100);
    double estimatedPrice = totalTsaiWithLoss * price;

    bool showInstruction = (l == 0 && w == 0 && t == 0);

    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2232),
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('木材用量計算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('計算才積與預估價格', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 輸入尺寸區
            const Text('輸入尺寸 (公分)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField('長度', _lengthCtrl, 'cm'),
                  const SizedBox(height: 12),
                  _buildInputField('寬度', _widthCtrl, 'cm'),
                  const SizedBox(height: 12),
                  _buildInputField('厚度', _thicknessCtrl, 'cm'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. 數量與價格區
            const Text('數量與價格', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField('件數', _qtyCtrl, '件'),
                  const SizedBox(height: 12),
                  _buildInputField('單價 (每才)', _priceCtrl, 'NT\$'),
                  const SizedBox(height: 12),
                  _buildInputField('耗損率', _lossCtrl, '%'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // 3. 才積說明區 / 計算結果區
            showInstruction 
                ? _buildInstructionCard() 
                : _buildResultCard(singleTsai, totalTsai, totalTsaiWithLoss, estimatedPrice),

            const SizedBox(height: 24),
            
            // 4. 底部提示
             Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '本工具僅供參考，實際施工請由專業師傅判斷。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => _calculate(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(hintText: '0', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              Text(unit, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('才積說明', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionText('• 1才 = 1台尺 × 1台尺 × 1台寸'),
          const SizedBox(height: 8),
          _buildInstructionText('• 1才 = 30.3cm × 30.3cm × 3.03cm = 2779.313 cm³'),
          const SizedBox(height: 8),
          _buildInstructionText('• 才積 = (長 cm × 寬 cm × 厚 cm) / 2779.313'),
          const SizedBox(height: 8),
          _buildInstructionText('• 木材價格通常以「每才」為單位報價'),
          const SizedBox(height: 8),
          _buildInstructionText('• 一般建議預留 8-10% 裁切損耗'),
        ],
      ),
    );
  }

  Widget _buildInstructionText(String text) {
    return Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5));
  }

  Widget _buildResultCard(double single, double total, double totalWithLoss, double price) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2232),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
        boxShadow: [BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildResultRow('單件才積', '${_format(single)} 才'),
          const SizedBox(height: 12),
          _buildResultRow('總才積 (未含損耗)', '${_format(total)} 才'),
          const SizedBox(height: 12),
          _buildResultRow('總才積 (含損耗)', '${_format(totalWithLoss)} 才'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.white12)),
          _buildResultRow('預估總金額', 'NT\$ ${_formatCurrency(price)}', isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isHighlight ? Colors.white : const Color(0xFF8A94A6), fontSize: isHighlight ? 16 : 14, fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: const Color(0xFFE5BA73), fontSize: isHighlight ? 24 : 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}