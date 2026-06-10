import 'package:flutter/material.dart';

class LengthConverterPage extends StatefulWidget {
  const LengthConverterPage({super.key});

  @override
  State<LengthConverterPage> createState() => _LengthConverterPageState();
}

class _LengthConverterPageState extends State<LengthConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  String _currentUnit = 'cm';
  double _inputValue = 0.0;

  final Map<String, double> _toCm = {
    'cm': 1.0,
    'mm': 0.1,
    'm': 100.0,
    't-chi': 30.3030303,
    't-tsun': 3.03030303,
    't-fen': 0.3030303,
    'in': 2.54,
    'ft': 30.48,
    'yd': 91.44,
  };

  final Map<String, String> _unitLabels = {
    'cm': '公分 (cm)',
    'mm': '公釐 (mm)',
    'm': '公尺 (m)',
    't-chi': '台尺',
    't-tsun': '台寸',
    't-fen': '台分',
    'in': '英吋 (in)',
    'ft': '英呎 (ft)',
    'yd': '碼 (yd)',
  };

  void _calculate(String value) {
    setState(() {
      _inputValue = double.tryParse(value) ?? 0.0;
    });
  }

  void _setShortcut(String unit, double value) {
    setState(() {
      _currentUnit = unit;
      // 如果是整數，去掉小數點，否則保留
      _inputController.text = value == value.toInt() ? value.toInt().toString() : value.toString();
      _inputValue = value;
    });
  }

  String _getConverted(String targetUnit) {
    if (_inputController.text.isEmpty) return '—';
    if (_inputValue == 0.0) return '0';
    
    double valueInCm = _inputValue * _toCm[_currentUnit]!;
    double targetValue = valueInCm / _toCm[targetUnit]!;
    
    // 格式化最多保留 4 位小數，去掉結尾多餘的 0
    String result = targetValue.toStringAsFixed(4);
    result = result.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    return result;
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
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
            Text('長度換算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('台尺 / 公制 / 英制 即時換算', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            const Text('快速帶入', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildShortcutBtn('1台尺 = ?cm', 't-chi', 1),
                _buildShortcutBtn('4×8 板 長邊', 'ft', 8),
                _buildShortcutBtn('1英吋 = ?mm', 'in', 1),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 輸入區塊
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('輸入數值', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // 單位切換 Tabs
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        _buildUnitTab('cm', '公分'),
                        _buildUnitTab('mm', '公釐'),
                        _buildUnitTab('m', '公尺'),
                        _buildUnitTab('t-chi', '台尺'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 數值輸入框
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121824),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_unitLabels[_currentUnit] ?? '未知單位', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                        TextField(
                          controller: _inputController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: _calculate,
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
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
            
            // 換算結果區塊
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('換算結果', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildResultRow('公釐 (mm)', 'mm'),
                  _buildResultRow('公尺 (m)', 'm'),
                  _buildResultRow('台尺', 't-chi'),
                  _buildResultRow('台寸', 't-tsun'),
                  _buildResultRow('台分', 't-fen'),
                  _buildResultRow('英吋 (in)', 'in'),
                  _buildResultRow('英呎 (ft)', 'ft'),
                  _buildResultRow('碼 (yd)', 'yd', isLast: true),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 底部提示
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '本工具僅供參考，實際施工請由專業師傅判斷。\n1台尺以 30.303 公分計算，1英吋以 2.54 公分計算。',
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

  Widget _buildShortcutBtn(String label, String unit, double value) {
    return OutlinedButton(
      onPressed: () => _setShortcut(unit, value),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        foregroundColor: const Color(0xFFE5BA73),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildUnitTab(String unit, String label) {
    final isSelected = _currentUnit == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentUnit = unit);
          _calculate(_inputController.text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5BA73).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String unit, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: isLast ? null : BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14)),
          Text(
            _getConverted(unit),
            style: const TextStyle(
              color: const Color(0xFFE5BA73), 
              fontSize: 18, 
              fontFamily: 'monospace', 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}