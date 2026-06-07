import 'package:flutter/material.dart';

class BoardThicknessCalculatorPage extends StatefulWidget {
  const BoardThicknessCalculatorPage({super.key});

  @override
  State<BoardThicknessCalculatorPage> createState() => _BoardThicknessCalculatorPageState();
}

class _BoardThicknessCalculatorPageState extends State<BoardThicknessCalculatorPage> {
  final TextEditingController _fenCtrl = TextEditingController(text: '1');

  double _mmValue = 3.03;
  double _cmValue = 0.303;
  double _inchValue = 0.119;

  // 常規 mm 反推分數的對照表 (確保常見板材反推的精確度)
  final Map<double, String> _mmToFenMap = {
    3: '1',
    4.5: '1.5',
    6: '2',
    7.5: '2.5',
    9: '3',
    12: '4',
    15: '5',
    18: '6',
    21: '7',
    24: '8',
    30: '10',
  };

  @override
  void initState() {
    super.initState();
    _calculate(); // 初始化計算一次預設值
  }

  void _calculate() {
    double fen = double.tryParse(_fenCtrl.text) ?? 0.0;

    setState(() {
      _mmValue = fen * 3.03;
      _cmValue = (fen * 3.03) / 10;
      _inchValue = fen * 0.119;
    });
  }

  // 點擊下方板材 mm 按鈕時的反向換算
  void _onMmSelected(double mm) {
    String fenStr;
    if (_mmToFenMap.containsKey(mm)) {
      fenStr = _mmToFenMap[mm]!; // 常規尺寸直接查表
    } else {
      // 非常規尺寸 (例如 25mm) 使用公式反推並保留小數點
      double calculatedFen = mm / 3.03;
      fenStr = calculatedFen.toStringAsFixed(2);
      fenStr = fenStr.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    
    setState(() {
      _fenCtrl.text = fenStr;
      _calculate();
    });
  }

  String _format(double val, int decimals) {
    if (val == 0) return '0';
    String s = val.toStringAsFixed(decimals);
    // 移除尾部多餘的 0
    s = s.replaceAll(RegExp(r'0*$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    return s.isEmpty ? '0' : s;
  }

  @override
  void dispose() {
    _fenCtrl.dispose();
    super.dispose();
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
            Text('木工分板厚度', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('分 ↔ mm 快速查詢', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 快速換算區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('快速換算', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('輸入分數', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                  const SizedBox(height: 8),
                  
                  // 輸入框
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121824),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fenCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (val) => _calculate(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.white24),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const Text('分', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 計算結果方塊
                  Row(
                    children: [
                      _buildCalcBox(_format(_mmValue, 2), 'mm'),
                      const SizedBox(width: 8),
                      _buildCalcBox(_format(_cmValue, 3), 'cm'),
                      const SizedBox(width: 8),
                      _buildCalcBox(_format(_inchValue, 3), 'inch'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. 常用厚度對照表區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('常用厚度對照表', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTableRow('分', 'mm', '常見用途', isHeader: true),
                  const SizedBox(height: 8),
                  _buildTableRow('1分', '3mm', '薄板、裝飾面板'),
                  _buildTableRow('1.5分', '4.5mm', '裝飾合板'),
                  _buildTableRow('2分', '6mm', '薄夾板、門片'),
                  _buildTableRow('2.5分', '7.5mm', '合板'),
                  _buildTableRow('3分', '9mm', '矽酸鈣板、合板'),
                  _buildTableRow('4分', '12mm', '石膏板、合板'),
                  _buildTableRow('5分', '15mm', '木芯板、合板'),
                  _buildTableRow('6分', '18mm', '木芯板、木地板'),
                  _buildTableRow('7分', '21mm', '厚木芯板'),
                  _buildTableRow('8分', '24mm', '特厚合板'),
                  _buildTableRow('10分', '30mm', '厚實木板', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. 常見板材規格區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('常見板材規格', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildMaterialSpecs('矽酸鈣板', '天花板、隔間', [6, 9, 12]),
                  const SizedBox(height: 16),
                  _buildMaterialSpecs('石膏板', '天花板、牆面', [9, 12, 15]),
                  const SizedBox(height: 16),
                  _buildMaterialSpecs('木芯板', '櫃體、門片', [15, 18]),
                  const SizedBox(height: 16),
                  _buildMaterialSpecs('夾板 (合板)', '各類用途', [3, 4.5, 6, 9, 12, 15, 18]),
                  const SizedBox(height: 16),
                  _buildMaterialSpecs('密集板 (MDF)', '家具、造型', [6, 9, 12, 18, 25]),
                  const SizedBox(height: 16),
                  _buildMaterialSpecs('塑合板', '系統櫃', [15, 18, 25]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 4. 底部提示
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                   child: Text('本工具僅供參考，實際施工請由專業師傅判斷。', style: TextStyle(color: const Color(0xFF8A94A6).withOpacity(0.8), fontSize: 12, height: 1.5)),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcBox(String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF121824),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(unit, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false, bool isLast = false}) {
    final Color textColor = isHeader ? const Color(0xFFE5BA73) : const Color(0xFFE0E0E0);
    final FontWeight weight = isHeader ? FontWeight.bold : FontWeight.normal;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(col1, style: TextStyle(color: textColor, fontWeight: weight, fontSize: 14))),
          Expanded(flex: 2, child: Text(col2, style: TextStyle(color: textColor, fontWeight: weight, fontSize: 14))),
          Expanded(flex: 4, child: Text(col3, style: TextStyle(color: isHeader ? textColor : const Color(0xFF8A94A6), fontWeight: weight, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildMaterialSpecs(String title, String usage, List<double> thicknessList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(usage, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: thicknessList.map((mm) {
            return InkWell(
              onTap: () => _onMmSelected(mm),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF121824),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text('${mm.toString().replaceAll(RegExp(r'\.0$'), '')}mm', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
