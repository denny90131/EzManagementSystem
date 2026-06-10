import 'package:flutter/material.dart';

// 定義五金資料結構
class HardwareCategory {
  final String name;
  final IconData icon;
  final List<String> tableHeaders;
  final List<List<String>> tableData;
  final List<String> suggestions;

  HardwareCategory({
    required this.name,
    required this.icon,
    required this.tableHeaders,
    required this.tableData,
    required this.suggestions,
  });
}

class HardwareReferencePage extends StatefulWidget {
  const HardwareReferencePage({super.key});

  @override
  State<HardwareReferencePage> createState() => _HardwareReferencePageState();
}

class _HardwareReferencePageState extends State<HardwareReferencePage> {
  int _currentIndex = 0;

  // 準備四個類別的硬體資料
  final List<HardwareCategory> _categories = [
    HardwareCategory(
      name: '螺絲',
      icon: Icons.bolt_outlined,
      tableHeaders: ['規格', '預鑽孔', '用途'],
      tableData: [
        ['#4 (2.2mm)', '1.5mm', '細木工、裝飾'],
        ['#6 (3.5mm)', '2.5mm', '一般木工、薄板'],
        ['#8 (4.2mm)', '3.0mm', '一般木工、合板'],
        ['#10 (4.8mm)', '3.5mm', '木芯板、厚板'],
        ['#12 (5.5mm)', '4.0mm', '結構、重載'],
        ['#14 (6.3mm)', '4.5mm', '重型結構'],
      ],
      suggestions: [
        '螺絲長度應為板材厚度的 2-2.5 倍',
        '預鑽孔可防止木材裂開',
        '硬木建議使用更細的預鑽孔',
      ],
    ),
    HardwareCategory(
      name: '釘子',
      icon: Icons.push_pin_outlined,
      tableHeaders: ['規格', '線徑', '用途'],
      tableData: [
        ['F15 (15mm)', '18GA', '裝飾條、收邊'],
        ['F20 (20mm)', '18GA', '薄板固定'],
        ['F25 (25mm)', '18GA', '面板、裝飾'],
        ['F30 (30mm)', '18GA', '一般固定'],
        ['F40 (40mm)', '18GA', '合板、木芯板'],
        ['F50 (50mm)', '18GA', '較厚板材'],
        ['T50 (50mm)', '16GA', '結構釘合'],
        ['T64 (64mm)', '16GA', '角材固定'],
        ['ST64 (64mm)', '14GA', '重型結構'],
      ],
      suggestions: [
        '18GA 適合裝飾與面板固定',
        '16GA 適合結構性釘合',
        '釘長應為板材厚度的 2 倍以上',
      ],
    ),
    HardwareCategory(
      name: '螺栓',
      icon: Icons.settings_outlined,
      tableHeaders: ['規格', '扳手', '用途'],
      tableData: [
        ['M3', '5.5mm', '小型五金'],
        ['M4', '7mm', '鉸鏈、小型固定'],
        ['M5', '8mm', '一般五金'],
        ['M6', '10mm', '門把、抽屜軌道'],
        ['M8', '13mm', '較重五金'],
        ['M10', '17mm', '結構連接'],
        ['M12', '19mm', '重型結構'],
      ],
      suggestions: [
        '螺栓長度需超過總厚度 + 螺帽高度',
        '使用墊圈可分散壓力',
        '不鏽鋼螺栓適合潮濕環境',
      ],
    ),
    HardwareCategory(
      name: '鉸鏈',
      icon: Icons.door_sliding_outlined,
      tableHeaders: ['規格', '角度', '用途'],
      tableData: [
        ['1" (25mm)', '90°', '小型門片、蓋板'],
        ['1.5" (38mm)', '90°', '小型櫃門'],
        ['2" (50mm)', '110°', '一般櫃門'],
        ['2.5" (63mm)', '110°', '標準門片'],
        ['3" (75mm)', '180°', '標準門、重門'],
        ['4" (100mm)', '180°', '大型門'],
      ],
      suggestions: [
        '門片重量決定鉸鏈數量',
        '一般門片至少使用 3 個鉸鏈',
        '重型門建議使用 4 個或承重型鉸鏈',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentCategory = _categories[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 統一深底色
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2232), // 統一卡片色
        foregroundColor: Colors.white,
        title: const Column(
          children: [
            Text('五金尺寸對照', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('常用五金規格查詢', style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
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
            // 1. 五金類別切換標籤 (Category Tabs Section)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_categories.length, (index) {
                  final category = _categories[index];
                  final isSelected = _currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE5BA73).withOpacity(0.15) : const Color(0xFF121824),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE5BA73) : Colors.white.withOpacity(0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(category.icon, color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6), size: 24),
                            const SizedBox(height: 6),
                            Text(
                              category.name,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // 2. 動態對照表格區 (Dynamic Table Card)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTableRow(
                    currentCategory.tableHeaders[0],
                    currentCategory.tableHeaders[1],
                    currentCategory.tableHeaders[2],
                    isHeader: true,
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(currentCategory.tableData.length, (idx) {
                    final row = currentCategory.tableData[idx];
                    return _buildTableRow(row[0], row[1], row[2], isLast: idx == currentCategory.tableData.length - 1);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. 選用建議區
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('💡', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text('選用建議', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 15, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...currentCategory.suggestions.map((sug) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text('• $sug', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13, height: 1.4)),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. 底部安全提示
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '本工具僅供參考，實際施工請由專業師傅判斷。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.5),
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

  // 共用繪製表格 Row 元件
  Widget _buildTableRow(String col1, String col2, String col3, {bool isHeader = false, bool isLast = false}) {
    final Color textColor = isHeader ? const Color(0xFFE5BA73) : const Color(0xFFE0E0E0);
    final FontWeight weight = isHeader ? FontWeight.bold : FontWeight.normal;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(col1, style: TextStyle(color: isHeader ? textColor : Colors.white, fontWeight: isHeader ? weight : FontWeight.bold, fontSize: 14))),
          Expanded(flex: 3, child: Text(col2, style: TextStyle(color: isHeader ? textColor : const Color(0xFF8A94A6), fontWeight: weight, fontSize: 14))),
          Expanded(flex: 4, child: Text(col3, style: TextStyle(color: isHeader ? textColor : const Color(0xFF8A94A6), fontWeight: weight, fontSize: 14))),
        ],
      ),
    );
  }
}