import 'package:flutter/material.dart';

class PaintConversionPage extends StatefulWidget {
  const PaintConversionPage({super.key});

  @override
  State<PaintConversionPage> createState() => _PaintConversionPageState();
}

class _PaintConversionPageState extends State<PaintConversionPage> {
  int _currentTab = 0; // 0: 加侖公斤換算, 1: 用量計算

  // Tab 1 Controllers
  final TextEditingController _galCtrl = TextEditingController(text: '1');
  final TextEditingController _sgCtrl = TextEditingController(text: '1.3');
  
  // Tab 2 Controllers
  final TextEditingController _areaCtrl = TextEditingController(text: '1');
  final TextEditingController _coatsCtrl = TextEditingController(text: '2');

  String _selectedPaint = '乳膠漆';

  final Map<String, Map<String, double>> _paintData = {
    '乳膠漆': {'sg': 1.3, 'cov': 10},
    '水泥漆': {'sg': 1.5, 'cov': 8},
    '油性漆': {'sg': 1.1, 'cov': 12},
    '木器漆': {'sg': 1.0, 'cov': 14},
    '防水漆': {'sg': 1.2, 'cov': 6},
    '底漆': {'sg': 1.2, 'cov': 10},
  };

  // Tab 1 Results
  double _lResult = 0.0;
  double _kgResult = 0.0;
  int _mlResult = 0;

  // Tab 2 Results
  double _totalLResult = 0.0;
  double _totalGalResult = 0.0;
  double _totalKgResult = 0.0;
  int _bucketsResult = 0;

  @override
  void initState() {
    super.initState();
    _calculateTab1();
    _calculateTab2();
  }

  @override
  void dispose() {
    _galCtrl.dispose();
    _sgCtrl.dispose();
    _areaCtrl.dispose();
    _coatsCtrl.dispose();
    super.dispose();
  }

  void _calculateTab1() {
    double gal = double.tryParse(_galCtrl.text) ?? 0.0;
    double sg = double.tryParse(_sgCtrl.text) ?? 0.0;

    setState(() {
      _lResult = gal * 3.7854;
      _kgResult = _lResult * sg;
      _mlResult = (_lResult * 1000).round();
    });
  }

  void _calculateTab2() {
    double area = double.tryParse(_areaCtrl.text) ?? 0.0;
    double coats = double.tryParse(_coatsCtrl.text) ?? 0.0;
    double cov = _paintData[_selectedPaint]!['cov']!;
    double sg = _paintData[_selectedPaint]!['sg']!;

    setState(() {
      _totalLResult = (area * coats) / cov;
      _totalGalResult = _totalLResult / 3.7854;
      _totalKgResult = _totalLResult * sg;
      _bucketsResult = _totalGalResult.ceil(); // 無條件進位
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 極深黑色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E), // 深灰色 Header
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('塗料換算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('比重換算 & 用量計算', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 主分頁切換 (Main Tabs)
            Row(
              children: [
                _buildTabButton(0, '加侖公斤換算'),
                const SizedBox(width: 12),
                _buildTabButton(1, '用量計算'),
              ],
            ),
            const SizedBox(height: 24),

            // 2. 依據分頁顯示對應內容
            if (_currentTab == 0) _buildTab1() else _buildTab2(),

            const SizedBox(height: 24),
            
            // 3. 底部安全提示
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

  Widget _buildTabButton(int index, String text) {
    bool isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8A94A6),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================
  // 分頁一：【加侖公斤換算】
  // =========================================
  Widget _buildTab1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('輸入換算', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildInputField('加侖數', _galCtrl, '加侖', _calculateTab1),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
              _buildInputField('塗料比重', _sgCtrl, 'g/cm³', _calculateTab1),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('換算結果', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              _buildNumberBox(_lResult.toStringAsFixed(2), '公升 (L)'),
              _buildNumberBox(_kgResult.toStringAsFixed(2), '公斤 (kg)'),
              _buildNumberBox(_mlResult.toString(), '毫升 (mL)'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('常用塗料比重參考', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: _paintData.entries.map((e) => _buildRefRow(e.key, e.value['sg']!, e.value['cov']!)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRefRow(String name, double sg, double cov) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Expanded(flex: 3, child: Text('比重 $sg', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14))),
          Expanded(flex: 3, child: Text('塗佈率 ${cov.toStringAsFixed(0)} m²/L', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14))),
        ],
      ),
    );
  }

  // =========================================
  // 分頁二：【用量計算】
  // =========================================
  Widget _buildTab2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('選擇塗料類型', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _paintData.keys.map((p) => _buildPaintChip(p)).toList(),
        ),
        const SizedBox(height: 24),
        const Text('尺寸輸入', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildInputField('施工面積', _areaCtrl, 'm²', _calculateTab2),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
              _buildInputField('塗刷次數', _coatsCtrl, '道', _calculateTab2),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('用量預估', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Text('${_totalLResult.toStringAsFixed(2)} L', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 40, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('預估所需塗料', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildNumberBox(_totalGalResult.toStringAsFixed(2), '加侖'),
                  _buildNumberBox(_totalKgResult.toStringAsFixed(2), '公斤'),
                  _buildNumberBox(_bucketsResult.toString(), '1加侖桶'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaintChip(String name) {
    bool isSelected = _selectedPaint == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaint = name;
          _calculateTab2(); // 選擇塗料後自動重新計算
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1)),
        ),
        child: Text(name, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8A94A6))),
      ),
    );
  }

  // =========================================
  // 共用 UI 元件
  // =========================================
  Widget _buildInputField(String label, TextEditingController ctrl, String unit, VoidCallback onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 15))),
        SizedBox(
          width: 100,
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white24),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(unit, textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildNumberBox(String val, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(unit, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
        ],
      ),
    );
  }
}