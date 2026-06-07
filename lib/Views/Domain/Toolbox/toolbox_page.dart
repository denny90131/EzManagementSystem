import 'package:flutter/material.dart';

class ToolboxPage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const ToolboxPage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 深底色
      appBar: AppBar(
        backgroundColor: const Color(0xFF121824), // 深底色
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman_rounded, color: Color(0xFFE5BA73)),
            SizedBox(width: 8),
            Text('工具箱', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('現場常用工具集中管理', style: TextStyle(fontSize: 16, color: Color(0xFF8A94A6), fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          
          // 工具列表
          _ToolTile(
            icon: Icons.square_foot_outlined, 
            title: '長度換算', 
            subtitle: '台尺 / 公制 / 英制 即時換算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LengthConverterPage())),
          ),
          _ToolTile(
            icon: Icons.view_in_ar_outlined, 
            title: '材積計算', 
            subtitle: '木材才數與立方米換算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VolumeCalculatorPage())),
          ),
          _ToolTile(icon: Icons.calculate_outlined, title: '工時計算', subtitle: '快速估算班別與加班', onTap: () {}),
          _ToolTile(icon: Icons.photo_camera_outlined, title: '照片紀錄', subtitle: '現場照片分類上傳', onTap: () {}),
          _ToolTile(icon: Icons.inventory_2_outlined, title: '材料清單', subtitle: '常用材料與數量', onTap: () {}),
          _ToolTile(icon: Icons.near_me_outlined, title: '快速派工', subtitle: '依空班人員派發任務', onTap: () {}),
          
          const SizedBox(height: 32),
          
          // 精選工具橫幅
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)], // 金色漸層
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.black),
                SizedBox(width: 12),
                Text(
                  '本週精選工具：AI 影像辨識',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 其他工具方格
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: List.generate(4, (index) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2232),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Center(
                      child: Text('其他工具 ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// 私有列表項目元件 (只在 ToolboxPage 使用)
class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2232),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE5BA73).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 28, color: const Color(0xFFE5BA73)),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(subtitle, style: const TextStyle(color: Color(0xFF8A94A6))),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF8A94A6)),
          ),
        ),
      ),
    );
  }
}

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

  final List<String> _units = ['cm', '台尺', '吋'];

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
            Text('支援 cm / 台尺 / 吋 混用換算', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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