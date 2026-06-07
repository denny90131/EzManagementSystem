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

  String _lengthUnit = 'cm';
  String _widthUnit = 'cm';
  String _thicknessUnit = 'cm';

  double _totalM3 = 0.0;
  double _totalTsai = 0.0;

  final List<String> _units = ['cm', 'mm', '台尺', '吋'];

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _thicknessCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    double l = double.tryParse(_lengthCtrl.text) ?? 0.0;
    double w = double.tryParse(_widthCtrl.text) ?? 0.0;
    double t = double.tryParse(_thicknessCtrl.text) ?? 0.0;
    double q = double.tryParse(_qtyCtrl.text) ?? 1.0;

    if (l == 0 || w == 0 || t == 0 || q == 0) {
      setState(() {
        _totalM3 = 0.0;
        _totalTsai = 0.0;
      });
      return;
    }

    // 將所有輸入轉換為公分 (cm)
    double lCm = _convertToCm(l, _lengthUnit);
    double wCm = _convertToCm(w, _widthUnit);
    double tCm = _convertToCm(t, _thicknessUnit);

    // 計算單件總體積 (cm³)
    double volumeCm3 = lCm * wCm * tCm * q;

    // 1 立方公尺 (m³) = 1,000,000 cm³
    // 1 才 (體積才) = 1台尺 x 1台尺 x 1台寸 = 30.303 x 30.303 x 3.0303 ≒ 2782.6 cm³
    setState(() {
      _totalM3 = volumeCm3 / 1000000.0;
      _totalTsai = volumeCm3 / 2782.6;
    });
  }

  double _convertToCm(double value, String unit) {
    switch (unit) {
      case '台尺':
        return value * 30.3030303;
      case '吋':
        return value * 2.54;
      case 'mm':
        return value * 0.1;
      case 'cm':
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2232),
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('材積計算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('支援 mm / cm / 台尺 / 吋 混用換算', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 計算結果區塊 (大字顯示置頂)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  const Text('總才數 (體積)', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_totalTsai.toStringAsFixed(2), style: const TextStyle(color: Colors.black, fontSize: 48, fontWeight: FontWeight.w900, height: 1.0)),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                        child: Text('才', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('總立方米', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      Text('${_totalM3.toStringAsFixed(4)} m³', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('輸入尺寸與數量', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 2. 輸入表單區塊
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildInputField('長度', _lengthCtrl, _lengthUnit, (val) => setState(() { _lengthUnit = val!; _calculate(); })),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
                  _buildInputField('寬度', _widthCtrl, _widthUnit, (val) => setState(() { _widthUnit = val!; _calculate(); })),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
                  _buildInputField('厚度', _thicknessCtrl, _thicknessUnit, (val) => setState(() { _thicknessUnit = val!; _calculate(); })),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
                  _buildInputField('數量', _qtyCtrl, '件', null),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '本工具採用體積才計算：\n1 才 = 1台尺 × 1台尺 × 1台寸\n若需計算面積才，請將厚度設為「1台寸」即可。',
                    style: TextStyle(color: const Color(0xFF8A94A6).withOpacity(0.8), fontSize: 12, height: 1.5),
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

  Widget _buildInputField(String label, TextEditingController controller, String unitValue, ValueChanged<String?>? onUnitChanged) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 16)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => _calculate(),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 80,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF121824),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: onUnitChanged != null 
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unitValue,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A2232),
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE5BA73), size: 20),
                    style: const TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.bold, fontSize: 14),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: onUnitChanged,
                  ),
                )
              : Center(
                  child: Text(unitValue, style: const TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.bold, fontSize: 14)),
                ),
        ),
      ],
    );
  }
}