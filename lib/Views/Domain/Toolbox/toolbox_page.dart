import 'package:flutter/material.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/length_converter_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/volume_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/wood_usage_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/paint_conversion_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/ceiling_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/board_thickness_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/hardware_reference_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/temperature_converter_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/angle_converter_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/pressure_converter_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/speed_converter_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/stair_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/cut_optimization_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/miter_angle_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/circle_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/wood_weight_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/moisture_calculator_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/water_pipe_calculator_page.dart';

class ToolboxPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ToolboxPage({super.key, this.userData});

  @override
  State<ToolboxPage> createState() => _ToolboxPageState();
}

class _ToolboxPageState extends State<ToolboxPage> {
  bool _isGridView = false; // false: 列表視圖, true: 網格視圖

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
            Icon(Icons.build, color: Color(0xFFE5BA73)),
            SizedBox(width: 8),
            Text('工具箱', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list_outlined : Icons.grid_view_outlined, color: const Color(0xFFE5BA73)),
            tooltip: _isGridView ? '切換為列表視圖' : '切換為網格視圖',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final tools = [
      _ToolInfo(Icons.square_foot_outlined, '長度換算', '台尺 / 公制 / 英制 即時換算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LengthConverterPage()))),
      _ToolInfo(Icons.view_in_ar_outlined, '材積計算', '木材才數與立方米換算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VolumeCalculatorPage()))),
      _ToolInfo(Icons.forest_outlined, '木材用量估算', '才積、耗損與價格換算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WoodUsageCalculatorPage()))),
      _ToolInfo(Icons.layers_outlined, '木工分板厚度', '分 ↔ mm 快速查詢', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardThicknessCalculatorPage()))),
      _ToolInfo(Icons.format_paint_outlined, '塗料換算', '比重換算 & 用量計算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaintConversionPage()))),
      _ToolInfo(Icons.grid_on_outlined, '天花板用量計算', '依坪數與板材估算片數', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CeilingCalculatorPage()))),
      _ToolInfo(Icons.hardware_outlined, '五金尺寸對照', '常用螺絲與鉸鏈規格', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HardwareReferencePage()))),
      _ToolInfo(Icons.thermostat_outlined, '溫度換算', '攝氏 / 華氏 / 克氏 即時換算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemperatureConverterPage()))),
      _ToolInfo(Icons.architecture_outlined, '角度換算', '度 / 弧度 / 百分度 即時換算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AngleConverterPage()))),
      _ToolInfo(Icons.speed_outlined, '壓力換算', 'Bar / PSI / kPa / atm 即時換算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PressureConverterPage()))),
      _ToolInfo(Icons.fast_forward_outlined, '速度換算', 'm/s / km/h / ft/min / mph 即時換算', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedConverterPage()))),
      _ToolInfo(Icons.stairs_outlined, '樓梯尺寸計算', '級高 / 級深 / 淨高 / 規範檢核', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StairCalculatorPage()))),
      _ToolInfo(Icons.cut_outlined, '切割優化', '一維板材/線材排程最省料', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CutOptimizationPage()))),
      _ToolInfo(Icons.category_outlined, '斜接角度計算', '相框與多邊形邊框斜角', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiterAngleCalculatorPage()))),
      _ToolInfo(Icons.pie_chart_outline, '圓形 / 弧形用料', '周長、面積、弧長、弦長', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CircleCalculatorPage()))),
      _ToolInfo(Icons.scale_outlined, '木材重量估算', '依木材種類密度估算重量', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WoodWeightCalculatorPage()))),
      _ToolInfo(Icons.water_drop_outlined, '含水率計算', '判斷木材適用情境', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoistureCalculatorPage()))),
      _ToolInfo(Icons.water_outlined, '水管管徑計算', '依設備或流量估算管徑與壓損', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterPipeCalculatorPage()))),
    ];

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return _ToolGridItem(
            icon: tool.icon,
            title: tool.title,
            onTap: tool.onTap,
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          return _ToolTile(
            icon: tool.icon,
            title: tool.title,
            subtitle: tool.subtitle,
            onTap: tool.onTap,
          );
        },
      );
    }
  }
}

// 用於儲存工具資訊的輔助 class
class _ToolInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ToolInfo(this.icon, this.title, this.subtitle, this.onTap);
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

// 私有網格項目元件 (只在 ToolboxPage 使用)
class _ToolGridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _ToolGridItem({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A2232),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: const Color(0xFFE5BA73)),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}