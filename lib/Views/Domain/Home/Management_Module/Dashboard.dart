import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 儀表板區塊，包含出勤率儀表板、蜂巢統計框和管理模組。
/// 負責處理其內部動畫和 UI 邏輯。
class DashboardSection extends StatefulWidget {
  final List<Map<String, dynamic>> teamMembers;
  final bool isLoading;

  const DashboardSection({
    super.key,
    required this.teamMembers,
    required this.isLoading,
  });

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 初始化儀表板動畫 (預設 0%，待 API 抓回資料後再動態計算目標進度)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 播放時間 1.5 秒
    );
    _animation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _updateAttendanceAnimation(); // 初次載入時更新動畫
  }

  @override
  void didUpdateWidget(covariant DashboardSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 當父 Widget 傳入的 teamMembers 數據更新時，重新觸發動畫
    if (oldWidget.teamMembers != widget.teamMembers) {
      _updateAttendanceAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 動態更新出勤率動畫
  void _updateAttendanceAnimation() {
    final workingCount = widget.teamMembers.where((m) => m['isWorking'] == true).length;
    final targetRatio = widget.teamMembers.isEmpty ? 0.0 : (workingCount / widget.teamMembers.length);
    
    _animation = Tween<double>(begin: _animation.value, end: targetRatio).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward(from: 0.0); // 觸發動畫
  }

  // 建立四個數據框的方法 (蜂巢六角形)
  Widget _buildHoneycombStat(String title, String count, Color color) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0), // 統一間距以確保蜂巢完美對齊
        child: CustomPaint(
          painter: _HoneycombPainter(
            backgroundColor: const Color(0xFF1A2232),
            borderColor: color.withOpacity(0.3),
          ),
          child: SizedBox(
            height: 96, // 恢復統一高度，達成完美蜂巢拼合
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(title, style: TextStyle(fontSize: 10, color: color.withOpacity(0.9), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 管理模組項目 (蜂巢六角形)
  Widget _buildHoneycombModule(String label, IconData icon, Color color) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {}, // 之後可以加上跳轉邏輯
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0), // 統一間距以確保蜂巢完美對齊
          child: CustomPaint(
            painter: _HoneycombPainter(
              backgroundColor: const Color(0xFF1A2232),
              borderColor: color.withOpacity(0.3),
            ),
            child: SizedBox(
              height: 96, // 恢復統一高度，達成完美蜂巢拼合
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32), // 將圖示明顯放大
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white, height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3. 今日出勤率儀表板 (在深色背景上的反白設計)
        Container(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return SizedBox(
                    width: 240,
                    height: 130, // 增加寬高，讓圓弧與文字保持更寬敞的距離
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        CustomPaint(
                          size: const Size(240, 120), // 放大儀表板半圓弧
                          painter: _DashboardGaugePainter(
                            progress: _animation.value, // 動態更新進度
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('今日出勤率', style: TextStyle(fontSize: 13, color: Color(0xFF8A94A6), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${(widget.isLoading ? 0 : _animation.value * 100).toInt()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4), // 些微下壓，拉開文字與頂端圓弧的距離
                          ],
                        ),
                      ],
                    ),
                  );
                }
              ),
            ],
          ),
        ),
        
        // 4. 四個統計框與管理模組 (穿插排版)
        Transform.translate(
          offset: const Offset(0, -20),
          child: Stack(
            children: [
              // 管理模組 (蜂巢六角形，穿插在下方空格)
              Padding(
                padding: const EdgeInsets.only(top: 72.0, left: 8.0, right: 8.0), // 剛好是高度 96 的 3/4 (72)，完美無縫咬合
                child: Row(
                  children: [
                    const Spacer(flex: 1), // 利用 Flex 比例讓中心點完美對齊菱形的縫隙
                    _buildHoneycombModule('零用金', Icons.account_balance_wallet_outlined, const Color(0xFFE5BA73)),
                    _buildHoneycombModule('成本分析', Icons.pie_chart_outline, Colors.blueAccent),
                    _buildHoneycombModule('出勤管理', Icons.payments_outlined, Colors.greenAccent),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
              // 四個統計框 (蜂巢六角形)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 數值目前為假資料，待 API 完成後可替換為真實變數
                    _buildHoneycombStat('工地', '0/12', const Color(0xFFE5BA73)),
                    _buildHoneycombStat('出工', '1/3', Colors.blue.shade100),
                    _buildHoneycombStat('工地回報', '22/45', Colors.greenAccent),
                    _buildHoneycombStat('出工回報', '2/18', Colors.redAccent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
              
// --- 汽車儀表板風格出勤率 ---
class _DashboardGaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;

  _DashboardGaugePainter({required this.progress, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0; // 將線條調細
    final paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = (size.width - paint.strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 繪製背景圓弧 (半圓: pi 到 2pi)
    canvas.drawArc(rect, math.pi, math.pi, false, paint);

    if (progress > 0) {
      // 1. 繪製進度圓弧 (純金色，移除發光與漸層)
      paint.color = const Color(0xFFE5BA73);
      canvas.drawArc(rect, math.pi, math.pi * progress, false, paint);

      // 2. 在最前端畫一個白點 (保留末端白光)
      final tipAngle = math.pi + (math.pi * progress);
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);
      
      final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 1.5, dotPaint); // 乾淨的白點
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.backgroundColor != backgroundColor;
  }
}

// --- 蜂巢六角形背景繪製 ---
class _HoneycombPainter extends CustomPainter {
  final Color borderColor;
  final Color backgroundColor;

  _HoneycombPainter({required this.borderColor, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    // 正統蜂巢比例：尖端佔總高度的 1/4 (0.25)
    final double pointH = size.height * 0.25; 
    final path = Path();
    path.moveTo(size.width / 2, 0); // 頂部中間
    path.lineTo(size.width, pointH); // 右上角
    path.lineTo(size.width, size.height - pointH); // 右下角
    path.lineTo(size.width / 2, size.height); // 底部中間
    path.lineTo(0, size.height - pointH); // 左下角
    path.lineTo(0, pointH); // 左上角
    path.close();

    final fillPaint = Paint()..color = backgroundColor..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()..color = borderColor..strokeWidth = 1.5..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HoneycombPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor || oldDelegate.backgroundColor != backgroundColor;
  }
}