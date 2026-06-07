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
          _ToolTile(
            icon: Icons.forest_outlined, 
            title: '木材用量估算', 
            subtitle: '才積、耗損與價格換算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WoodUsageCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.layers_outlined, 
            title: '木工分板厚度', 
            subtitle: '分 ↔ mm 快速查詢', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BoardThicknessCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.format_paint_outlined, 
            title: '塗料換算', 
            subtitle: '比重換算 & 用量計算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaintConversionPage())),
          ),
          _ToolTile(
            icon: Icons.grid_on_outlined, 
            title: '天花板用量計算', 
            subtitle: '依坪數與板材估算片數', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CeilingCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.hardware_outlined, 
            title: '五金尺寸對照', 
            subtitle: '常用螺絲與鉸鏈規格', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HardwareReferencePage())),
          ),
          _ToolTile(
            icon: Icons.thermostat_outlined, 
            title: '溫度換算', 
            subtitle: '攝氏 / 華氏 / 克氏 即時換算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemperatureConverterPage())),
          ),
          _ToolTile(
            icon: Icons.architecture_outlined, 
            title: '角度換算', 
            subtitle: '度 / 弧度 / 百分度 即時換算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AngleConverterPage())),
          ),
          _ToolTile(
            icon: Icons.speed_outlined, 
            title: '壓力換算', 
            subtitle: 'Bar / PSI / kPa / atm 即時換算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PressureConverterPage())),
          ),
          _ToolTile(
            icon: Icons.fast_forward_outlined, 
            title: '速度換算', 
            subtitle: 'm/s / km/h / ft/min / mph 即時換算', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeedConverterPage())),
          ),
          _ToolTile(
            icon: Icons.stairs_outlined, 
            title: '樓梯尺寸計算', 
            subtitle: '級高 / 級深 / 淨高 / 規範檢核', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StairCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.cut_outlined, 
            title: '切割優化', 
            subtitle: '一維板材/線材排程最省料', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CutOptimizationPage())),
          ),
          _ToolTile(
            icon: Icons.category_outlined, 
            title: '斜接角度計算', 
            subtitle: '相框與多邊形邊框斜角', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiterAngleCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.pie_chart_outline, 
            title: '圓形 / 弧形用料', 
            subtitle: '周長、面積、弧長、弦長', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CircleCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.scale_outlined, 
            title: '木材重量估算', 
            subtitle: '依木材種類密度估算重量', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WoodWeightCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.water_drop_outlined, 
            title: '含水率計算', 
            subtitle: '判斷木材適用情境', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoistureCalculatorPage())),
          ),
          _ToolTile(
            icon: Icons.water_outlined, 
            title: '水管管徑計算', 
            subtitle: '依設備或流量估算管徑與壓損', 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterPipeCalculatorPage())),
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