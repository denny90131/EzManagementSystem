import 'package:flutter/material.dart';

class VolumeCalculatorPage extends StatefulWidget {
  const VolumeCalculatorPage({super.key});

  @override
  State<VolumeCalculatorPage> createState() => _VolumeCalculatorPageState();
}

class _VolumeCalculatorPageState extends State<VolumeCalculatorPage> {
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _thicknessCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');

  int _selectedTab = 0; // 0: 台灣材積, 1: 日本材積, 2: 公制體積

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _thicknessCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {}); // 觸發畫面重繪，數值會在 build 中即時計算
  }

  String _format(double val) {
    if (val == 0) return '0';
    // 最多保留 6 位小數，並移除尾部多餘的 0 與小數點
    String s = val.toStringAsFixed(6);
    s = s.replaceAll(RegExp(r'0*$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s.isEmpty ? '0' : s;
  }

  String _getMainResultText(double totalCm3) {
    if (_selectedTab == 0) return '${_format(totalCm3 / 27826.117)} 才';
    if (_selectedTab == 1) return '${_format(totalCm3 / 278261.17)} 石';
    return '${_format(totalCm3 / 1000000.0)} m³';
  }

  @override
  Widget build(BuildContext context) {
    double l = double.tryParse(_lengthCtrl.text) ?? 0.0;
    double w = double.tryParse(_widthCtrl.text) ?? 0.0;
    double t = double.tryParse(_thicknessCtrl.text) ?? 0.0;
    double q = double.tryParse(_qtyCtrl.text) ?? 1.0;

    double singleCm3 = l * w * t;
    double vCm3 = singleCm3 * q;
    bool showInstruction = (vCm3 == 0); // 體積為0時顯示說明

    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2232),
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('材積計算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('木材材積快速計算', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 分類切換標籤 (Tabs Section)
            Row(
              children: [
                _buildTab(0, '台灣材積 (才)'),
                _buildTab(1, '日本材積 (石)'),
                _buildTab(2, '公制體積 (m³)'),
              ],
            ),

            const SizedBox(height: 24),
            const Text('輸入尺寸 (公分)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 2. 輸入表單區塊
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
                  _buildInputField('厚度 / 高度', _thicknessCtrl, 'cm'),
                  const SizedBox(height: 12),
                  _buildInputField('數量', _qtyCtrl, '支'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 3. 換算說明區 / 計算結果區
            showInstruction ? _buildInstructionCard() : _buildResultCard(vCm3, singleCm3),

            const SizedBox(height: 24),
            
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

  Widget _buildTab(int index, String title) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5BA73).withOpacity(0.15) : const Color(0xFF1A2232),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFE5BA73) : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2232),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💡', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('材積換算說明', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstructionText('• 1才 = 1台尺 × 1台尺 × 10台尺\n  (30.3cm × 30.3cm × 303cm)'),
          const SizedBox(height: 8),
          _buildInstructionText('• 1台尺 = 30.3公分'),
          const SizedBox(height: 8),
          _buildInstructionText('• 1石 ≈ 10才'),
          const SizedBox(height: 8),
          _buildInstructionText('• 輸入公分，自動換算各單位'),
        ],
      ),
    );
  }

  Widget _buildInstructionText(String text) {
    return Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5));
  }

  Widget _buildResultCard(double totalCm3, double singleCm3) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2232),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            _getMainResultText(totalCm3),
            style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 32, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 16),
          ..._buildDetailRows(totalCm3, singleCm3),
        ],
      ),
    );
  }

  List<Widget> _buildDetailRows(double totalCm3, double singleCm3) {
    if (_selectedTab == 0) {
      return [
        _buildResultRow('單支材積', '${_format(singleCm3 / 27826.117)} 才'),
        const SizedBox(height: 12),
        _buildResultRow('總材積', '${_format(totalCm3 / 27826.117)} 才'),
        const SizedBox(height: 12),
        _buildResultRow('換算立方公尺', '${_format(totalCm3 / 1000000.0)} m³'),
      ];
    } else if (_selectedTab == 1) {
      return [
        _buildResultRow('單支材積 (石)', '${_format(singleCm3 / 278261.17)} 石'),
        const SizedBox(height: 12),
        _buildResultRow('總材積 (石)', '${_format(totalCm3 / 278261.17)} 石'),
        const SizedBox(height: 12),
        _buildResultRow('換算台才 (才)', '${_format(totalCm3 / 27826.117)} 才'),
      ];
    } else {
      return [
        _buildResultRow('單支體積', '${_format(singleCm3 / 1000000.0)} m³'),
        const SizedBox(height: 12),
        _buildResultRow('總體積', '${_format(totalCm3 / 1000000.0)} m³'),
        const SizedBox(height: 12),
        _buildResultRow('換算台才', '${_format(totalCm3 / 27826.117)} 才'),
        const SizedBox(height: 12),
        _buildResultRow('換算立方英呎', '${_format(totalCm3 / 28316.84659)} ft³'),
      ];
    }
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
}