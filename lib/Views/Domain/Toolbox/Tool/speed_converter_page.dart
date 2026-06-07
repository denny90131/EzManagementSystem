import 'package:flutter/material.dart';

class SpeedConverterPage extends StatefulWidget {
  const SpeedConverterPage({super.key});

  @override
  State<SpeedConverterPage> createState() => _SpeedConverterPageState();
}

class _SpeedConverterPageState extends State<SpeedConverterPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _currentUnit = 'm/s'; // 預設單位
  double? _inputValue;

  // 速度單位轉換基礎：以 公尺/秒 (m/s) 為中繼基準點
  // 為了完美咬合您提供的測試案例精度，這裡採用對應的精確常數
  final Map<String, double> _toTarget = {
    'm/s': 1.0,
    'km/h': 3.6,
    'ft/min': 196.8504,
    'mph': 2.2369,
  };

  final Map<String, String> _unitNames = {
    'm/s': '公尺/秒 (m/s)',
    'km/h': '公里/時 (km/h)',
    'ft/min': '英尺/分 (ft/min)',
    'mph': '英里/時 (mph)',
  };

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
      // 如果是整數，去掉小數點，否則保留
      _inputCtrl.text = value == value.toInt() ? value.toInt().toString() : value.toString();
      _inputValue = value;
    });
  }

  String _format(double? val) {
    if (val == null) return '—';
    // 格式化最多保留 4 位小數，並移除尾部多餘的 0
    String s = val.toStringAsFixed(4);
    s = s.replaceAll(RegExp(r'0*$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    if (s == '-0') return '0'; // 防呆
    return s.isEmpty ? '0' : s;
  }

  // 核心轉換邏輯：算出目標單位的數值
  double? _getConverted(String targetUnit) {
    if (_inputValue == null) return null;
    if (_currentUnit == targetUnit) return _inputValue;
    
    // 先除以當前單位的常數，換算回純粹的 m/s 中繼值，再乘上目標單位常數
    double baseMs = _inputValue! / _toTarget[_currentUnit]!;
    return baseMs * _toTarget[targetUnit]!;
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
            Text('速度換算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('m/s / km/h / ft/min / mph 即時換算', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
                      _buildShortcutBtn('1 m/s = ? km/h', 'm/s', 1),
                      _buildShortcutBtn('100 ft/min = ? m/s', 'ft/min', 100),
                      _buildShortcutBtn('60 mph = ? km/h', 'mph', 60),
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
                  
                  // 單位切換標籤 (Tabs)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildUnitTab('m/s', _unitNames['m/s']!),
                      _buildUnitTab('km/h', _unitNames['km/h']!),
                      _buildUnitTab('ft/min', _unitNames['ft/min']!),
                      _buildUnitTab('mph', _unitNames['mph']!),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 輸入框
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_unitNames[_currentUnit]!, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
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
                  if (_currentUnit != 'm/s') _buildResultRow(_unitNames['m/s']!, _format(_getConverted('m/s'))),
                  if (_currentUnit != 'km/h') _buildResultRow(_unitNames['km/h']!, _format(_getConverted('km/h'))),
                  if (_currentUnit != 'ft/min') _buildResultRow(_unitNames['ft/min']!, _format(_getConverted('ft/min'))),
                  if (_currentUnit != 'mph') _buildResultRow(_unitNames['mph']!, _format(_getConverted('mph')), isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. 專業說明區 (Explanation Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('說明', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('• 用於計算截切刀片轉速與推給料速度 (如 CNC 常用 ft/min)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, height: 1.4)),
                  SizedBox(height: 6),
                  Text('• 1 m/s = 3.6 km/h = 196.85 ft/min = 2.237 mph', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, height: 1.4)),
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

  Widget _buildShortcutBtn(String label, String unit, double value) {
    return OutlinedButton(
      onPressed: () => _setShortcut(unit, value),
      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.1)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), foregroundColor: const Color(0xFFE5BA73), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildUnitTab(String unit, String label) {
    bool isSelected = _currentUnit == unit;
    return GestureDetector(
      onTap: () {
        setState(() => _currentUnit = unit);
        _calculate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05), width: 1.5)),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8A94A6), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
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
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Text(value, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}