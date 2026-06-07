import 'package:flutter/material.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/length_converter_page.dart';
import 'package:ez_manager/Views/Domain/Toolbox/Tool/volume_calculator_page.dart';

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
              gradient: const LinearGradient(
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