import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircleCalculatorPage extends StatefulWidget {
  const CircleCalculatorPage({super.key});

  @override
  State<CircleCalculatorPage> createState() => _CircleCalculatorPageState();
}

class _CircleCalculatorPageState extends State<CircleCalculatorPage> {
  final TextEditingController _radiusCtrl = TextEditingController(text: '0');
  final TextEditingController _angleCtrl = TextEditingController(text: '360');

  double? _fullCircumference;
  double? _fullArea;
  double? _arcLength;
  double? _sectorArea;
  double? _chordLength;
  String _angleTitleStr = '360';

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _angleCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    double r = double.tryParse(_radiusCtrl.text) ?? 0.0;
    double theta = double.tryParse(_angleCtrl.text) ?? 0.0;

    // 限制角度在 0 ~ 360 (防呆)，也可允許大於360(若需計算累積長度)
    // 依據您的需求，這裡先照著輸入數值計算。
    setState(() {
      _angleTitleStr = _angleCtrl.text.trim().isEmpty ? '一' : _angleCtrl.text.trim();

      if (r <= 0) {
        _fullCircumference = null;
        _fullArea = null;
        _arcLength = null;
        _sectorArea = null;
        _chordLength = null;
      } else {
        // 整圓計算
        _fullCircumference = 2 * math.pi * r;
        _fullArea = math.pi * r * r;

        // 弧度與弦長
        double rad = theta * (math.pi / 180.0);
        _arcLength = (theta / 360.0) * 2 * math.pi * r;
        _sectorArea = (theta / 360.0) * math.pi * r * r;
        _chordLength = 2 * r * math.sin(rad / 2);
      }
    });
  }

  String _format(double? val) {
    if (val == null) return '—';
    // 一律固定保留到小數點後兩位
    return val.toStringAsFixed(2);
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
            Text('圓形 / 弧形用料', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('周長、面積、弧長、弦長', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 輸入尺寸區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputField('半徑 r', _radiusCtrl, 'cm'),
                  const SizedBox(height: 16),
                  _buildInputField('夾角 (整圓填 360)', _angleCtrl, '°'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 整圓結果區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('整圓', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildResultRow('周長 (2πr)', _fullCircumference, 'cm', isHighlight: false),
                  _buildResultRow('面積 (πr²)', _fullArea, 'cm²', isHighlight: false, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 扇形 / 弧形動態結果區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '扇形 / 弧 (',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: '$_angleTitleStr°', style: const TextStyle(color: Color(0xFFD4AF37))),
                        const TextSpan(text: ')'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResultRow('弧長', _arcLength, 'cm', isHighlight: true),
                  _buildResultRow('扇形面積', _sectorArea, 'cm²', isHighlight: true),
                  _buildResultRow('弦長 (兩端直線距離)', _chordLength, 'cm', isHighlight: true, isLast: true),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),
                  
                  // 4. 公式與提示說明
                  const Text('公式：弧長=θ÷360×2πr，弦長=2r×sin(θ÷2)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.5)),
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

  Widget _buildResultRow(String label, double? value, String unit, {bool isHighlight = false, bool isLast = false}) {
    bool isNull = value == null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isNull ? '—' : _format(value),
                style: TextStyle(
                  color: const Color(0xFFD4AF37),
                  fontSize: isHighlight ? 28 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isNull) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(unit, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14)),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}