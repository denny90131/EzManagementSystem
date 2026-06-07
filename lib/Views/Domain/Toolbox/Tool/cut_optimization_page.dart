import 'package:flutter/material.dart';

class StockMaterial {
  double capacity;
  double remaining;
  List<double> cuts = [];

  StockMaterial(this.capacity) : remaining = capacity;
}

class CutOptimizationPage extends StatefulWidget {
  const CutOptimizationPage({super.key});

  @override
  State<CutOptimizationPage> createState() => _CutOptimizationPageState();
}

class _CutOptimizationPageState extends State<CutOptimizationPage> {
  final TextEditingController _stockLengthCtrl = TextEditingController(text: '300');
  final TextEditingController _kerfCtrl = TextEditingController(text: '3');
  final TextEditingController _reqCtrl = TextEditingController(text: '120,90,90,60');

  List<StockMaterial> _stocks = [];
  double _utilizationRate = 0.0;
  double _totalRemaining = 0.0;
  int _totalCutPieces = 0;
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _stockLengthCtrl.dispose();
    _kerfCtrl.dispose();
    _reqCtrl.dispose();
    super.dispose();
  }

  // 解析使用者輸入字串，支援 "120" 或 "120x3" 格式
  List<double> _parseInput(String input) {
    List<double> result = [];
    List<String> parts = input.split(RegExp(r'[,，]+')); // 支援全半形逗號

    for (String part in parts) {
      part = part.trim().toLowerCase();
      if (part.isEmpty) continue;
      
      if (part.contains('x') || part.contains('*')) {
        List<String> sub = part.split(RegExp(r'[x*]'));
        if (sub.length == 2) {
          double? len = double.tryParse(sub[0].trim());
          int? count = int.tryParse(sub[1].trim());
          if (len != null && count != null && count > 0) {
            for (int i = 0; i < count; i++) {
              result.add(len);
            }
          }
        }
      } else {
        double? len = double.tryParse(part);
        if (len != null) {
          result.add(len);
        }
      }
    }
    return result;
  }

  void _calculate() {
    setState(() {
      _hasError = false;
      _errorMsg = '';
      _stocks.clear();
      _utilizationRate = 0.0;
      _totalRemaining = 0.0;
      _totalCutPieces = 0;
    });

    double stockCapacity = double.tryParse(_stockLengthCtrl.text) ?? 0.0;
    double kerfMm = double.tryParse(_kerfCtrl.text) ?? 0.0;
    double kerfCm = kerfMm / 10.0; // 轉換為 cm

    if (stockCapacity <= 0) return;

    List<double> reqLengths = _parseInput(_reqCtrl.text);
    if (reqLengths.isEmpty) return;

    // 演算法：First Fit Decreasing (FFD) 遞減貪婪演算法
    // 1. 將需求從大到小排序，優先排入長料
    reqLengths.sort((a, b) => b.compareTo(a));

    List<StockMaterial> resultStocks = [];
    double totalPureCutLength = 0.0;

    for (double req in reqLengths) {
      if (req > stockCapacity) {
        setState(() {
          _hasError = true;
          _errorMsg = '錯誤：需求長度 ($req cm) 超過原料長度 ($stockCapacity cm)';
        });
        return;
      }

      bool placed = false;
      for (StockMaterial stock in resultStocks) {
        // 第一刀不扣鋸縫，後續同根原料每多一刀加扣一次鋸縫
        double neededSpace = stock.cuts.isEmpty ? req : req + kerfCm;
        
        if (stock.remaining >= neededSpace) {
          stock.cuts.add(req);
          stock.remaining -= neededSpace;
          placed = true;
          totalPureCutLength += req;
          break;
        }
      }

      // 如果現有原料都放不下，開一根新的
      if (!placed) {
        StockMaterial newStock = StockMaterial(stockCapacity);
        newStock.cuts.add(req);
        newStock.remaining -= req; // 第一刀不扣鋸縫
        resultStocks.add(newStock);
        totalPureCutLength += req;
      }
    }

    double totalRemaining = 0.0;
    for (var s in resultStocks) {
      totalRemaining += s.remaining;
    }

    double totalProvidedVolume = resultStocks.length * stockCapacity;
    double utilization = totalProvidedVolume > 0 ? (totalPureCutLength / totalProvidedVolume) * 100 : 0.0;

    setState(() {
      _stocks = resultStocks;
      _totalCutPieces = reqLengths.length;
      _totalRemaining = totalRemaining;
      _utilizationRate = utilization;
    });
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
            Text('切割優化', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('一維板材切割排程，最省料', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 原料規格區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('原料規格', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInputField('原料長度', _stockLengthCtrl, 'cm'),
                  const SizedBox(height: 12),
                  _buildInputField('鋸縫寬度 (鋸片厚度)', _kerfCtrl, 'mm'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 需要的長度清單區
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('需要的長度清單', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('範例：120,90,90,60 或 120x3,90x2 (cm)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF121824), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
                    child: TextField(
                      controller: _reqCtrl,
                      keyboardType: TextInputType.text,
                      onChanged: (_) => _calculate(),
                      style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: '輸入裁切尺寸...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text('⚠️ $_errorMsg', style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 總計統計卡片區 & 排料視覺化清單區 (有計算結果才顯示)
            if (_stocks.isNotEmpty && !_hasError) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('總計', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildResultRow('需要原料', '${_stocks.length} 根'),
                    _buildResultRow('切出件數', '$_totalCutPieces 件'),
                    _buildResultRow('剩料總長', '${_totalRemaining.toStringAsFixed(1)} cm'),
                    _buildResultRow('材料利用率', '${_utilizationRate.toStringAsFixed(1)} %', isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 視覺化清單
              ...List.generate(_stocks.length, (index) {
                StockMaterial stock = _stocks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2232),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('原料 #${index + 1} (${stock.capacity.toStringAsFixed(0)} cm)', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: stock.cuts.map((cutSize) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5BA73).withOpacity(0.15),
                              border: Border.all(color: const Color(0xFFE5BA73)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${cutSize.toString().replaceAll(RegExp(r'\.0$'), '')} cm', style: const TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.bold, fontSize: 13)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Colors.white12),
                      const SizedBox(height: 12),
                      Text('剩料: ${stock.remaining.toStringAsFixed(1)} cm', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                    ],
                  ),
                );
              }),
            ],
            
            const SizedBox(height: 8),

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

  Widget _buildResultRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value, style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}