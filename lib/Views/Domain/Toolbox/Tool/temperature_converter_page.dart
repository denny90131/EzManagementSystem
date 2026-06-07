import 'package:flutter/material.dart';

class TemperatureConverterPage extends StatefulWidget {
  const TemperatureConverterPage({super.key});

  @override
  State<TemperatureConverterPage> createState() => _TemperatureConverterPageState();
}

class _TemperatureConverterPageState extends State<TemperatureConverterPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _currentUnit = 'C'; // 'C', 'F', 'K'
  double? _inputValue;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      if (_inputCtrl.text.trim().isEmpty) {
        _inputValue = null;
      } else {
        _inputValue = double.tryParse(_inputCtrl.text);
      }
    });
  }

  void _setShortcut(String unit, double value) {
    setState(() {
      _currentUnit = unit;
      _inputCtrl.text = value == value.toInt() ? value.toInt().toString() : value.toString();
      _inputValue = value;
    });
  }

  String _format(double? val) {
    if (val == null) return '—';
    // 最多保留 4 位小數，並移除尾部多餘的 0
    String s = val.toStringAsFixed(4);
    s = s.replaceAll(RegExp(r'0*$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    if (s == '-0') return '0'; // 避免出現 -0 的特例
    return s;
  }

  // 核心轉換邏輯：以攝氏 (C) 為中繼橋樑
  double? _getC() {
    if (_inputValue == null) return null;
    if (_currentUnit == 'C') return _inputValue;
    if (_currentUnit == 'F') return (_inputValue! - 32) * 5 / 9;
    if (_currentUnit == 'K') return _inputValue! - 273.15;
    return null;
  }

  double? _getF() {
    if (_inputValue == null) return null;
    if (_currentUnit == 'F') return _inputValue;
    double? c = _getC();
    if (c != null) return (c * 9 / 5) + 32;
    return null;
  }

  double? _getK() {
    if (_inputValue == null) return null;
    if (_currentUnit == 'K') return _inputValue;
    double? c = _getC();
    if (c != null) return c + 273.15;
    return null;
  }

  String _getUnitLabel(String unit) {
    switch (unit) {
      case 'C': return '攝氏 (°C)';
      case 'F': return '華氏 (°F)';
      case 'K': return '克氏 (K)';
      default: return '';
    }
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
            Text('溫度換算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('攝氏 / 華氏 / 克氏 即時換算', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 快速帶入區 (Quick Shortcuts Card)
            Container(
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
                      _buildShortcutBtn('水的沸點 100°C', 'C', 100),
                      _buildShortcutBtn('體溫 37°C', 'C', 37),
                      _buildShortcutBtn('室溫 72°F', 'F', 72),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 輸入數值區 (Input Section)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('輸入數值', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildUnitTab('C', '攝氏 (°C)'),
                      const SizedBox(width: 8),
                      _buildUnitTab('F', '華氏 (°F)'),
                      const SizedBox(width: 8),
                      _buildUnitTab('K', '克氏 (K)'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getUnitLabel(_currentUnit), style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                        TextField(
                          controller: _inputCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          onChanged: (_) => _calculate(),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.white24),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 換算結果區 (Result Section)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('換算結果', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_currentUnit != 'C') _buildResultRow('攝氏 (°C)', _format(_getC())),
                  if (_currentUnit != 'F') _buildResultRow('華氏 (°F)', _format(_getF())),
                  if (_currentUnit != 'K') _buildResultRow('克氏 (K)', _format(_getK()), isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. 底部安全提示
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

  Widget _buildShortcutBtn(String label, String unit, double value) {
    return OutlinedButton(
      onPressed: () => _setShortcut(unit, value),
      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), foregroundColor: const Color(0xFFE5BA73), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildUnitTab(String unit, String label) {
    bool isSelected = _currentUnit == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentUnit = unit);
          _calculate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFFE5BA73).withOpacity(0.15) : const Color(0xFF1A2232), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? const Color(0xFFE5BA73) : Colors.white.withOpacity(0.05), width: 1.5)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(value, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}