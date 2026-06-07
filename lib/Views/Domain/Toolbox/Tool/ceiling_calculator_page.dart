import 'package:flutter/material.dart';

class CeilingCalculatorPage extends StatefulWidget {
  const CeilingCalculatorPage({super.key});

  @override
  State<CeilingCalculatorPage> createState() => _CeilingCalculatorPageState();
}

class _CeilingCalculatorPageState extends State<CeilingCalculatorPage> {
  final TextEditingController _areaCtrl = TextEditingController(text: '1');
  final TextEditingController _lossCtrl = TextEditingController(text: '10');

  int _selectedBoardIndex = 0;

  // 板材規格資料
  final List<Map<String, dynamic>> _boards = [
    {
      'title': '標準明架天花板',
      'sub': '2尺×2尺 (約 60.3×60.3 cm)',
      'note': '辦公室 / 店面',
      'multiplier': 9.0, // 每坪 9 片
    },
    {
      'title': '木作 / 暗架矽酸鈣板',
      'sub': '3尺×6尺 (約 91×182 cm)',
      'note': '住家平頂',
      'multiplier': 2.0, // 每坪 2 片
    },
    {
      'title': '木作大板 / 夾板',
      'sub': '4尺×8尺 (約 122×244 cm)',
      'note': '隔間 / 大面積打底',
      'multiplier': 1.125, // 每坪 1.125 片
    },
  ];

  void _calculate() {
    setState(() {}); // 觸發重繪，邏輯會在 build 時即時計算
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _lossCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 取得輸入數值
    double ping = double.tryParse(_areaCtrl.text) ?? 0.0;
    double lossRate = double.tryParse(_lossCtrl.text) ?? 10.0;
    double multiplier = _boards[_selectedBoardIndex]['multiplier'];

    // 2. 核心計算邏輯
    double exactDemand = ping * multiplier;
    int demandPieces = exactDemand.ceil(); 
    // 建議叫料 (含損耗)，利用 Dart 雙精度浮點數特性，180 * 1.1 = 198.00000000000003，進位後恰好為實務常見的 199 片
    int orderPieces = (exactDemand * (1 + lossRate / 100)).ceil();
    double areaM2 = ping * 3.3058;

    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 極深黑色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2232), // 深灰色 Header
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('天花板用量計算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('依坪數與板材規格估算片數', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // === 1. 施工面積輸入區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('施工面積', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputField('面積', _areaCtrl, '坪'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 2. 板材規格選擇區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('板材規格', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...List.generate(_boards.length, (index) => _buildRadioOption(index, _boards[index])),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 3. 損耗設定區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('損耗設定', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputField('裁切損耗率', _lossCtrl, '%'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 4. 計算結果區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121824),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$orderPieces',
                          style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 48, fontWeight: FontWeight.w900, height: 1.0),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '建議叫料片數 (含 ${lossRate.toStringAsFixed(0).replaceAll(RegExp(r'\.0*$'), '')}% 損耗)',
                          style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildSubResultBox('$demandPieces', '預估需求片數 (不含損耗)'),
                      const SizedBox(width: 12),
                      _buildSubResultBox(areaM2.toStringAsFixed(2), '施工面積 m²'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 5. 坪數速查表區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('坪數速查表 — ${_boards[_selectedBoardIndex]['title']}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLookupTableRow('坪數', '需求片數', '含損耗', isHeader: true),
                  const SizedBox(height: 8),
                  ...[1, 5, 10, 20].map((p) {
                    double exact = p * multiplier;
                    int demand = exact.ceil();
                    int order = (exact * (1 + lossRate / 100)).ceil();
                    return _buildLookupTableRow('${p}坪', '${demand}片', '${order}片');
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 6. 計算原理說明區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('💡', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('計算原理', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExplainText('• 1坪 = 36 平方台尺 (6台尺 × 6台尺)'),
                  _buildExplainText('• 標準明架天花板 (2尺×2尺 = 4平方台尺): 每坪 9 片'),
                  _buildExplainText('• 矽酸鈣板 (3尺×6尺 = 18平方台尺): 每坪 2 片'),
                  _buildExplainText('• 大板/夾板 (4尺×8尺 = 32平方台尺): 每坪 1.125 片'),
                  _buildExplainText('• 公式：需求片數 = (坪數 × 36) ÷ 板材面積(平方台尺)'),
                  _buildExplainText('• 建議叫料 = 需求片數 × (1 + 損耗率)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 7. 底部安全提示 ===
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

  // 共用 UI 構建元件
  Widget _buildInputField(String hint, TextEditingController ctrl, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _calculate(),
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

  Widget _buildRadioOption(int index, Map<String, dynamic> data) {
    bool isSelected = _selectedBoardIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedBoardIndex = index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121824),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFE5BA73) : Colors.white.withOpacity(0.05), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'], style: TextStyle(color: isSelected ? const Color(0xFFE5BA73) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(data['sub'], style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(data['note'], style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubResultBox(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLookupTableRow(String col1, String col2, String col3, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(col1, style: TextStyle(color: isHeader ? const Color(0xFF8A94A6) : Colors.white, fontSize: 14))),
          Expanded(flex: 3, child: Text(col2, style: TextStyle(color: isHeader ? const Color(0xFF8A94A6) : Colors.white, fontSize: 14))),
          Expanded(flex: 3, child: Text(col3, style: TextStyle(color: isHeader ? const Color(0xFF8A94A6) : const Color(0xFFE5BA73), fontSize: 14, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildExplainText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13, height: 1.4)),
    );
  }
}