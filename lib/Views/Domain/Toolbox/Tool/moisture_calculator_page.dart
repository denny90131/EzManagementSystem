import 'package:flutter/material.dart';

class MoistureCalculatorPage extends StatefulWidget {
  const MoistureCalculatorPage({super.key});

  @override
  State<MoistureCalculatorPage> createState() => _MoistureCalculatorPageState();
}

class _MoistureCalculatorPageState extends State<MoistureCalculatorPage> {
  final TextEditingController _wetCtrl = TextEditingController();
  final TextEditingController _dryCtrl = TextEditingController();

  double? _waterWeight;
  double? _mcResult;

  @override
  void dispose() {
    _wetCtrl.dispose();
    _dryCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    double wet = double.tryParse(_wetCtrl.text) ?? 0.0;
    double dry = double.tryParse(_dryCtrl.text) ?? 0.0;

    setState(() {
      if (wet <= 0 || dry <= 0) {
        _waterWeight = null;
        _mcResult = null;
        return;
      }

      // 1. 計算含水重量 (失重值)
      _waterWeight = wet - dry;
      
      // 2. 烘乾法含水率公式 (以乾重為基材分母)
      _mcResult = (_waterWeight! / dry) * 100.0;
    });
  }

  // 格式化輸出
  String _format(double? val) {
    if (val == null) return '—';
    return val.toStringAsFixed(2);
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
            Text('含水率計算', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('判斷木材適用情境', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 秤重輸入區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('秤重輸入', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('取小塊試樣，秤目前重量 = 濕重；\n放入烘箱 103±2°C 至恆重 = 乾重', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12, height: 1.4)),
                  const SizedBox(height: 16),
                  _buildInputField('濕重 (目前)', _wetCtrl, 'g'),
                  const SizedBox(height: 12),
                  _buildInputField('乾重 (烘乾後)', _dryCtrl, 'g'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 換算結果區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('換算結果', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildResultRow('含水重量', _format(_waterWeight), 'g', isHighlight: false),
                  _buildResultRow('含水率 (MC)', _format(_mcResult), '%', isHighlight: true, isLast: true),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 16),
                  const Text('公式：MC = (濕重 - 乾重) ÷ 乾重 × 100%', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. 動態環境診斷警示區
            if (_mcResult != null) _buildDiagnosticBlock(_mcResult!),
            const SizedBox(height: 24),

            // 4. 常用含水率對照表區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('常用含水率對照', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTableRow('< 6%', '過乾'),
                  _buildTableRow('6 - 12%', '室內傢俱級'),
                  _buildTableRow('12 - 15%', '一般室內'),
                  _buildTableRow('15 - 20%', '戶外可用'),
                  _buildTableRow('> 20%', '濕材', isLast: true),
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

  Widget _buildResultRow(String label, String value, String unit, {bool isHighlight = false, bool isLast = false}) {
    bool isNull = value == '—';
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
                value,
                style: TextStyle(
                  color: isHighlight && !isNull ? const Color(0xFFE5BA73) : (isNull ? const Color(0xFFE5BA73) : Colors.white),
                  fontSize: isHighlight && !isNull ? 32 : 18,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              if (!isNull) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: EdgeInsets.only(bottom: isHighlight ? 4.0 : 0.0),
                  child: Text(unit, style: TextStyle(color: isHighlight ? const Color(0xFFE5BA73) : Colors.white, fontSize: 14)),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticBlock(double mc) {
    String badgeText;
    Color badgeColor;
    String diagText;
    Color textColor;

    if (mc > 20) {
      badgeText = '濕材';
      badgeColor = Colors.redAccent;
      diagText = '含水率過高，需窯乾或氣乾後再使用，否則會嚴重變形。';
      textColor = Colors.red.shade200;
    } else if (mc >= 15) {
      badgeText = '戶外可用';
      badgeColor = Colors.orangeAccent;
      diagText = '此含水率適用於戶外結構，室內家具容易抽心變形。';
      textColor = Colors.orange.shade200;
    } else if (mc >= 6) {
      badgeText = '室內合格';
      badgeColor = Colors.green;
      diagText = '含水率處於黃金區間，適合製作高級室內傢俱與地板，結構穩定。';
      textColor = Colors.green.shade100;
    } else {
      badgeText = '過乾';
      badgeColor = Colors.blueGrey;
      diagText = '木材過於乾燥，注意室內大回潮時可能產生膨脹開裂。';
      textColor = Colors.blueGrey.shade100;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12), border: Border.all(color: badgeColor.withOpacity(0.5), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
            child: Text(badgeText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 16),
          Text(diagText, style: TextStyle(color: textColor, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTableRow(String col1, String col2, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(
        children: [
          Expanded(child: Text(col1, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14))),
          Expanded(child: Text(col2, style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }
}