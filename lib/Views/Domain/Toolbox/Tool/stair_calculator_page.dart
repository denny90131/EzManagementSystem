import 'package:flutter/material.dart';
import 'dart:math' as math;

class StairCalculatorPage extends StatefulWidget {
  const StairCalculatorPage({super.key});

  @override
  State<StairCalculatorPage> createState() => _StairCalculatorPageState();
}

class _StairCalculatorPageState extends State<StairCalculatorPage> {
  // Controllers
  final TextEditingController _heightCtrl = TextEditingController(text: '300');
  final TextEditingController _fixedRunCtrl = TextEditingController(text: '27');
  final TextEditingController _fixedLenCtrl = TextEditingController(text: '400');
  final TextEditingController _openingCtrl = TextEditingController(text: '200');
  final TextEditingController _slabCtrl = TextEditingController(text: '15');

  // Tabs State
  int _calcMode = 0; // 0: 自動, 1: 固定級深, 2: 固定總長
  int _ruleMode = 0; // 0: 台灣住宅, 1: 台灣公共, 2: 美國 IBC
  int _userGroup = 0; // 0: 標準成人, 1: 老人/兒童

  // 法規常數表
  final List<Map<String, double>> _rules = [
    {'maxR': 20.0, 'minG': 21.0, 'minH': 190.0}, // TW Res
    {'maxR': 18.0, 'minG': 24.0, 'minH': 190.0}, // TW Pub
    {'maxR': 19.7, 'minG': 25.4, 'minH': 203.0}, // US IBC
  ];

  final List<String> _ruleNames = ['台灣 住宅', '台灣 公共', '美國 IBC'];

  // 計算結果變數
  int _steps = 0;
  double _rise = 0.0;
  double _run = 0.0;
  double _totalLength = 0.0;
  double _angle = 0.0;
  double _strideMm = 0.0;
  List<Map<String, dynamic>> _stepHeadrooms = [];
  bool _hasHeadbump = false;
  double _minFoundHeadroom = double.infinity;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _fixedRunCtrl.dispose();
    _fixedLenCtrl.dispose();
    _openingCtrl.dispose();
    _slabCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    double h = double.tryParse(_heightCtrl.text) ?? 300.0;
    double opening = double.tryParse(_openingCtrl.text) ?? 200.0;
    double slab = double.tryParse(_slabCtrl.text) ?? 15.0;

    if (h <= 0) return;

    double idealR = _userGroup == 0 ? 17.0 : 15.0; // 成人約 17, 老人兒童約 15
    int n = 0;
    double r = 0.0;
    double g = 0.0;

    if (_calcMode == 0) {
      // 自動 (步幅法則)
      n = (h / idealR).round();
      r = h / n;
      g = 62.0 - (2 * r);
    } else if (_calcMode == 1) {
      // 固定級深
      g = double.tryParse(_fixedRunCtrl.text) ?? 27.0;
      double targetR = (62.0 - g) / 2.0;
      n = (h / targetR).round();
      if (n <= 0) n = 1;
      r = h / n;
    } else if (_calcMode == 2) {
      // 固定總長
      double l = double.tryParse(_fixedLenCtrl.text) ?? 400.0;
      n = (h / idealR).round();
      r = h / n;
      g = l / (n > 1 ? n - 1 : 1);
    }

    // 基礎計算
    double totalLen = g * (n - 1);
    double angle = math.atan(r / g) * (180 / math.pi);
    double stride = (2 * r + g) * 10; // 換算 mm

    // 淨高檢測
    List<Map<String, dynamic>> stepList = [];
    bool headbump = false;
    double minHead = double.infinity;
    double ruleMinH = _rules[_ruleMode]['minH']!;

    for (int k = 1; k < n; k++) {
      // 該階距離頂端樓層邊緣的水平距離
      double distFromTop = (n - k) * g;
      bool isUnderSlab = distFromTop > opening;
      double headroom = h - slab - (r * k);
      bool isDanger = false;

      if (isUnderSlab) {
        if (headroom < ruleMinH) {
          isDanger = true;
          headbump = true;
        }
        if (headroom < minHead) {
          minHead = headroom;
        }
      }

      stepList.add({
        'k': k,
        'headroom': headroom,
        'isDanger': isDanger,
        'underSlab': isUnderSlab,
      });
    }

    setState(() {
      _steps = n;
      _rise = r;
      _run = g;
      _totalLength = totalLen;
      _angle = angle;
      _strideMm = stride;
      _stepHeadrooms = stepList;
      _hasHeadbump = headbump;
      _minFoundHeadroom = minHead;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('樓梯計算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('級高 / 級深 / 淨高 / 規範檢核', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 基本尺寸區
            _buildCard(
              title: '基本尺寸',
              child: Column(
                children: [
                  _buildInputField('樓層總高 (200-600)', _heightCtrl, 'cm'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildTabBtn(0, _calcMode, '自動 (步幅法則)', (v) => setState(() { _calcMode = v; _calculate(); })),
                      const SizedBox(width: 8),
                      _buildTabBtn(1, _calcMode, '固定級深', (v) => setState(() { _calcMode = v; _calculate(); })),
                      const SizedBox(width: 8),
                      _buildTabBtn(2, _calcMode, '固定總長', (v) => setState(() { _calcMode = v; _calculate(); })),
                    ],
                  ),
                  if (_calcMode == 1) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
                    _buildInputField('指定級深 (建議 24-30)', _fixedRunCtrl, 'cm'),
                  ],
                  if (_calcMode == 2) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
                    _buildInputField('指定樓梯總長 (150-800)', _fixedLenCtrl, 'cm'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 淨高參數區
            _buildCard(
              title: '淨高參數 (撞頭檢測)',
              child: Column(
                children: [
                  _buildInputField('⭐️ 樓板開口長度', _openingCtrl, 'cm'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.white12)),
                  _buildInputField('樓板厚度 (含裝修, 10-30)', _slabCtrl, 'cm'),
                  if (_hasHeadbump) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withOpacity(0.5))),
                      child: const Row(
                        children: [
                          Text('⚠️', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Expanded(child: Text('樓板開口長度不夠，走到中段會撞到上層樓板', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 規範與客群區
            _buildCard(
              title: '規範與客群選取',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTabBtn(0, _ruleMode, '台灣 住宅', (v) => setState(() { _ruleMode = v; _calculate(); })),
                      const SizedBox(width: 8),
                      _buildTabBtn(1, _ruleMode, '台灣 公共', (v) => setState(() { _ruleMode = v; _calculate(); })),
                      const SizedBox(width: 8),
                      _buildTabBtn(2, _ruleMode, '美國 IBC', (v) => setState(() { _ruleMode = v; _calculate(); })),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildTabBtn(0, _userGroup, '標準成人', (v) => setState(() { _userGroup = v; _calculate(); })),
                      const SizedBox(width: 8),
                      _buildTabBtn(1, _userGroup, '老人 / 兒童', (v) => setState(() { _userGroup = v; _calculate(); })),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. 計算結果區
            _buildCard(
              title: '計算結果',
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Text('$_steps 階', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 42, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildResultRow('級高 (Rise)', '${_rise.toStringAsFixed(2)} cm'),
                  _buildResultRow('級深 (Run)', '${_run.toStringAsFixed(2)} cm'),
                  _buildResultRow('樓梯總長', '${_totalLength.toStringAsFixed(1)} cm'),
                  _buildResultRow('傾斜角', '${_angle.toStringAsFixed(1)}°'),
                  _buildResultRow('2R+G 步幅值', '${_strideMm.toStringAsFixed(0)} mm', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. 法規與工學符合性檢核區
            _buildCard(
              title: '規範符合性 — ${_ruleNames[_ruleMode]}',
              child: Column(
                children: [
                  _buildCheckRow('級高', _rise, '<=', _rules[_ruleMode]['maxR']!, 'cm'),
                  _buildCheckRow('級深', _run, '>=', _rules[_ruleMode]['minG']!, 'cm'),
                  _buildCheckRow('淨高', _minFoundHeadroom, '>=', _rules[_ruleMode]['minH']!, 'cm', isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: '人體工學評估',
              child: _buildErgonomicsCheck(),
            ),
            const SizedBox(height: 24),

            // 6. 每階淨高明細
            _buildCard(
              title: '每階淨高 (上方有樓板覆蓋)',
              child: Column(
                children: [
                  if (_stepHeadrooms.where((s) => s['underSlab']).isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('所有階梯皆在開口範圍內，無撞頭風險', style: TextStyle(color: Colors.greenAccent, fontSize: 14)),
                    )
                  else
                    ..._stepHeadrooms.map((step) {
                      if (!step['underSlab']) return const SizedBox(); // 僅顯示在樓板下方的階梯
                      bool isDanger = step['isDanger'];
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('階 ${step['k']}', style: TextStyle(color: isDanger ? Colors.redAccent : Colors.white, fontSize: 14, fontWeight: isDanger ? FontWeight.bold : FontWeight.normal)),
                            Row(
                              children: [
                                Text('${step['headroom'].toStringAsFixed(1)} cm', style: TextStyle(color: isDanger ? Colors.redAccent : const Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                                if (isDanger) const Padding(padding: EdgeInsets.only(left: 8.0), child: Text('⚠️', style: TextStyle(fontSize: 14))),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  const Text('公式：淨高 (階k) = 樓層高 - 樓板厚 - 級高 × k', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 7. 法規參考常數說明區
            _buildCard(
              title: '法規參考',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• 台灣 建築技術規則 §33：\n  住宅級高 ≤ 20cm、級深 ≥ 21cm\n  公共級高 ≤ 18cm、級深 ≥ 24cm\n  淨高 ≥ 190cm', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.5)),
                  SizedBox(height: 8),
                  Text('• 美國 IBC 2021：\n  住宅級高 ≤ 19.7cm、級深 ≥ 25.4cm、淨高 ≥ 203cm', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.5)),
                  SizedBox(height: 8),
                  Text('• 本工具僅供參考，實際施工請由合格建築師/營造商執行', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Footer
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

  // UI Builders
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController ctrl, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
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
              Text(unit, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBtn(int index, int currentValue, String label, ValueChanged<int> onSelect) {
    bool isSelected = currentValue == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : const Color(0xFF121212),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF8A94A6), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String label, double actual, String operator, double limit, String unit, {bool isLast = false}) {
    bool isPass = operator == '<=' ? actual <= limit : actual >= limit;
    // 如果最低淨高是無限大（代表沒人在樓板下），強制判定通過
    if (label == '淨高' && actual == double.infinity) isPass = true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(
        children: [
          Icon(isPass ? Icons.check_circle : Icons.cancel, color: isPass ? Colors.greenAccent : Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(
            actual == double.infinity ? '安全 (無遮蔽)' : '${actual.toStringAsFixed(1)} $unit',
            style: TextStyle(color: isPass ? Colors.greenAccent : Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (actual != double.infinity) ...[
            const SizedBox(width: 8),
            Text('($operator $limit)', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
          ]
        ],
      ),
    );
  }

  Widget _buildErgonomicsCheck() {
    bool isGood = _strideMm >= 600 && _strideMm <= 650;
    bool isTooSmall = _strideMm < 600;
    
    String msg = isGood ? '舒適 (步幅在 60-65cm 黃金區間)' : (isTooSmall ? '步幅偏小，樓梯太平緩' : '步幅過大，爬梯較費力');
    Color color = isGood ? Colors.greenAccent : Colors.orangeAccent;
    IconData icon = isGood ? Icons.check_circle : Icons.warning_amber_rounded;

    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(msg, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('依據 Blondel 法則 (2R + G = 60~65cm)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}