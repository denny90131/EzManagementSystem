import 'package:flutter/material.dart';

class WoodWeightCalculatorPage extends StatefulWidget {
  const WoodWeightCalculatorPage({super.key});

  @override
  State<WoodWeightCalculatorPage> createState() => _WoodWeightCalculatorPageState();
}

class _WoodWeightCalculatorPageState extends State<WoodWeightCalculatorPage> {
  final TextEditingController _lengthCtrl = TextEditingController(text: '1');
  final TextEditingController _widthCtrl = TextEditingController(text: '2');
  final TextEditingController _thicknessCtrl = TextEditingController(text: '5');
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');

  int _selectedWoodIndex = 0;

  final List<Map<String, dynamic>> _woods = [
    {'name': '杉木', 'density': 380},
    {'name': '檜木', 'density': 440},
    {'name': '松木', 'density': 500},
    {'name': '夾板', 'density': 600},
    {'name': '柚木', 'density': 650},
    {'name': '胡桃木', 'density': 660},
    {'name': '樺木', 'density': 670},
    {'name': '楓木', 'density': 700},
    {'name': '橡木', 'density': 750},
    {'name': 'MDF (密集板)', 'density': 750},
  ];

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _thicknessCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {}); // 觸發重繪，數值會在 build 中即時計算
  }

  @override
  Widget build(BuildContext context) {
    // 1. 取得輸入數值
    double l = double.tryParse(_lengthCtrl.text) ?? 0.0;
    double w = double.tryParse(_widthCtrl.text) ?? 0.0;
    double t = double.tryParse(_thicknessCtrl.text) ?? 0.0;
    double q = double.tryParse(_qtyCtrl.text) ?? 0.0;
    int density = _woods[_selectedWoodIndex]['density'];

    // 2. 核心計算邏輯
    double volCm3 = l * w * t;
    double volL = volCm3 / 1000.0;
    double volM3 = volCm3 / 1000000.0;
    
    double unitWeight = volM3 * density;
    double totalWeight = unitWeight * q;

    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 統一深底色
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2232), // 統一卡片色
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('木材重量估算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('依木材種類密度估算重量', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // === 1. 木材尺寸輸入區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('木材尺寸 (cm)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputField('長', _lengthCtrl, 'cm'),
                  const SizedBox(height: 12),
                  _buildInputField('寬', _widthCtrl, 'cm'),
                  const SizedBox(height: 12),
                  _buildInputField('厚', _thicknessCtrl, 'cm'),
                  const SizedBox(height: 12),
                  _buildInputField('數量', _qtyCtrl, '支'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 2. 木材種類選擇區 ===
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('木材種類', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _woods.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final wood = _woods[index];
                        final isSelected = _selectedWoodIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedWoodIndex = index;
                              _calculate();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE5BA73).withOpacity(0.15) : const Color(0xFF121824),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFFE5BA73) : Colors.white.withOpacity(0.05), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(wood['name'], style: TextStyle(color: isSelected ? const Color(0xFFE5BA73) : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('${wood['density']} kg/m³', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 3. 換算結果區 ===
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultRow('單支體積', '${volL.toStringAsFixed(3)} L', isHighlight: false),
                  _buildResultRow('單支重量', '${unitWeight.toStringAsFixed(2)} kg', isHighlight: false),
                  _buildResultRow('總重量', '${totalWeight.toStringAsFixed(2)} kg', isHighlight: true, isLast: true),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),
                  
                  const Text('註：密度為氣乾材平均值，實際隨產地、含水率有 ±15% 誤差。', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === 4. 底部安全提示 ===
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

  Widget _buildInputField(String label, TextEditingController ctrl, String unit) {
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
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _calculate(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                ),
              ),
              Text(unit, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
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