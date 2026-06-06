import 'dart:ui';
import 'package:flutter/material.dart';
import '../Domain/Home/home_page.dart';
import '../Domain/petty_cash_page.dart';
import '../Domain/report_page.dart';
import '../Domain/toolbox_page.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const MainScreen({super.key, this.userData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 定義四個分頁的畫面
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(userData: widget.userData),
      ToolboxPage(userData: widget.userData),
      ReportPage(userData: widget.userData),
      PettyCashPage(userData: widget.userData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBody 設為 true 是關鍵！這可以讓 body 延伸到底部導航欄的下方，使毛玻璃效果顯現
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ClipRRect(
        // ClipRRect 防止模糊效果溢出到非導航欄的區域
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: BottomNavigationBar(
            // 深色毛玻璃背景
            backgroundColor: const Color(0xFF1A2232).withOpacity(0.85),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFFE5BA73), // 選中時金色
            unselectedItemColor: const Color(0xFF8A94A6), // 未選中半透明灰
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁'),
              BottomNavigationBarItem(icon: Icon(Icons.build), label: '工具箱'),
              BottomNavigationBarItem(icon: Icon(Icons.report), label: '回報'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: '零用金'),
            ],
          ),
        ),
      ),
    );
  }
}