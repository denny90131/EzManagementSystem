import 'package:flutter/material.dart';

class MiterAngleCalculatorPage extends StatefulWidget {
  const MiterAngleCalculatorPage({super.key});

  @override
  State<MiterAngleCalculatorPage> createState() => _MiterAngleCalculatorPageState();
}

class _MiterAngleCalculatorPageState extends State<MiterAngleCalculatorPage> {
  final TextEditingController _sidesCtrl = TextEditingController(text: '4');

  double? _interiorAngle;
  double? _exteriorAngle;
  double? _miterAngle;
  double? _sawScale;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _sidesCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    int n = int.tryParse(_sidesCtrl.text) ?? 0;

    setState(() {
      if (n >= 3) {
        _interiorAngle = ((n - 2) * 180) / n;
        _exteriorAngle = 360 / n;
        _miterAngle = 180 / n;
        _sawScale = 90 - (180 / n);
      } else {
        _interiorAngle = null;
        _exteriorAngle = null;
        _miterAngle = null;
        _sawScale = null;
      }
    });
  }

  void _setShortcut(int n) {
    setState(() {
      _sidesCtrl.text = n.toString();
      _calculate();
    });
  }

  String _format(double? val) {
    if (val == null) return '—';
    // 依需求固定保留小數點後兩位
    return val.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 統一深底色
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2232), // 統一卡片色
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('斜接角度', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('多邊形邊框、相框斜切角度', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 快速帶入區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('快速帶入', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildShortcutBtn('正方形 (4)', 4),
                      _buildShortcutBtn('六角形 (6)', 6),
                      _buildShortcutBtn('八角形 (8)', 8),
                      _buildShortcutBtn('十二角形 (12)', 12),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 輸入邊數區
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('輸入邊數', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('邊數 (n ≥ 3)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _sidesCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                                onChanged: (_) => _calculate(),
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                              ),
                            ),
                            const Text('邊', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 換算結果區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('換算結果', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildResultRow('內角', '${_format(_interiorAngle)}°', isHighlight: false),
                  _buildResultRow('外角', '${_format(_exteriorAngle)}°', isHighlight: false),
                  _buildResultRow('每邊斜切角度', '${_format(_miterAngle)}°', isHighlight: true),
                  _buildResultRow('鋸台刻度設定', '${_format(_sawScale)}°', isHighlight: false, isLast: true),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),
                  
                  // 4. 公式與提示說明
                  const Text('公式：內角=(n-2)×180÷n，斜切角=180÷n', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.5)),
                  const SizedBox(height: 4),
                  const Text('提示：『斜切角』是兩邊接合處每根料各自要切的角度；『鋸台刻度』是 90 度減斜切角後的設定值', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. 底部安全提示
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text('本工具僅供參考，實際施工請由專業師傅判斷。', style: TextStyle(color: const Color(0xFF8A94A6).withOpacity(0.8), fontSize: 12, height: 1.5))),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutBtn(String label, int value) {
    return OutlinedButton(
      onPressed: () => _setShortcut(value),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        foregroundColor: const Color(0xFFE5BA73),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? const Color(0xFFE5BA73) : Colors.white,
              fontSize: isHighlight ? 28 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}