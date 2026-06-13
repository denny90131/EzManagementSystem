import 'package:flutter/material.dart';
import 'dart:ui';

// --- 案件詳細頁面 (點擊案件卡片時導覽) ---
class CaseDetailPage extends StatefulWidget {
  const CaseDetailPage({super.key});

  @override
  State<CaseDetailPage> createState() => _CaseDetailPageState();
}

class _CaseDetailPageState extends State<CaseDetailPage> {
  int _currentTab = 1; // 0: 會議紀錄, 1: 現況照

  Widget _buildTab(int index, String title) {
    bool isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6),
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          if (isSelected)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE5BA73),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 深色背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF121824), // 深色背景
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('工地資料', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Color(0xFFE5BA73)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 2. 專案資料分類標籤
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Row(
              children: [
                _buildTab(0, '會議紀錄'),
                const SizedBox(width: 24),
                _buildTab(1, '現況照'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 3. 照片網格內容區
          if (_currentTab == 1)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 9 / 16, // 16:9 垂直長方型
                        ),
                        itemCount: 4, // 模擬 4 張圖片
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF121824),
                              borderRadius: BorderRadius.circular(8),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/placeholder.png'), // 請確保專案有此圖片，或替換為 NetworkImage
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: const Center(child: Icon(Icons.image_outlined, color: Color(0xFF8A94A6), size: 36)),
                          );
                        },
                      ),
                    ),
                    // 統計與下載操作 Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2232),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('共 4 張圖片', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 14)),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1A2232),
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('下載全部圖片', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 4. 會議紀錄區 (Tab 0)
          if (_currentTab == 0)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2232),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF8A94A6)),
                    const SizedBox(height: 16),
                    const Text('目前尚無會議紀錄', style: TextStyle(color: Color(0xFF8A94A6))),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRecordScreen())),
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text('新增紀錄', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5BA73)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      // 4. 底部固定操作欄與漂浮按鈕
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE5BA73),
        child: const Icon(Icons.home_outlined, color: Colors.black, size: 28),
        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2232), // 深色卡片
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('上傳圖片', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF121824),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE5BA73)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5BA73), // 金色按鈕
                    foregroundColor: Colors.black, // 黑字
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('回報進度', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 新增紀錄頁面 ---
class AddRecordScreen extends StatelessWidget {
  const AddRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 極深黑背景
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E), // 深灰 Header
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 16)),
        ),
        title: const Text('新增紀錄', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('紀錄已儲存')));
              Navigator.pop(context);
            },
            child: const Text('確認', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // 表單容器淺灰底(Dark mode 下的深灰卡片)
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 區塊 A: 公開紀錄
              const Text('公開紀錄', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 14)),
              const SizedBox(height: 12),
              TextField(
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '請輸入公開的會議內容',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.image_outlined, color: Color(0xFF8A94A6), size: 32),
                    SizedBox(height: 8),
                    Text('公開上傳圖片', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 區塊 B: 非公開紀錄 (隱私虛線框設計)
              CustomPaint(
                painter: _DashedRectPainter(color: Colors.white30, strokeWidth: 1.5, gap: 6, dash: 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('非公開紀錄', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 14, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.visibility_off_outlined, color: Color(0xFFE5BA73), size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '此資料填寫後僅內部可見...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF121212),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.image_outlined, color: Color(0xFF8A94A6), size: 32),
                            SizedBox(height: 8),
                            Text('隱藏圖片', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 繪製虛線圓角矩形的 CustomPainter
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;

  _DashedRectPainter({this.color = Colors.white, this.strokeWidth = 1.0, this.gap = 5.0, this.dash = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    final Path path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));
    
    Path dashPath = Path();
    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(pathMetric.extractPath(distance, distance + dash), Offset.zero);
        distance += dash;
        distance += gap;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}