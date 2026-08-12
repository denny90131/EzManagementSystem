import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../Authenticator/Login.dart';
import '../Domain/Home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '易派工',
      debugShowCheckedModeBanner: false, // 隱藏右上角 Debug 標籤
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'TW'), // 繁體中文
      ],
      // 全域防爆版與文字縮放處理
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(boldText: false),
          child: child!,
        );
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFE5BA73), // 主要金色
          secondary: const Color(0xFFC19A5B), // 金色漸層輔助
          surface: const Color(0xFF1A2232), // 卡片底色
        ),
        scaffoldBackgroundColor: const Color(0xFF121824), // 深底色
        dividerColor: Colors.white12,

        // 1. 全域文字主題 (預設純白)
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
        ),

        // 2. AppBar 風格
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121824),
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          centerTitle: true,
        ),

        // 3. 輸入框風格
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A2232),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5BA73), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF8A94A6)),
          floatingLabelStyle: const TextStyle(color: Color(0xFFE5BA73)),
          prefixIconColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const Color(0xFFE5BA73);
            }
            return const Color(0xFF8A94A6);
          }),
        ),

        // 4. 按鈕風格
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5BA73),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE5BA73),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // 5. 卡片與彈窗風格
        cardTheme: CardThemeData(
          color: const Color(0xFF1A2232),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1A2232),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1A2232),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),

        // 6. Checkbox 風格
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFFE5BA73);
            }
            return const Color(0xFF8A94A6);
          }),
          checkColor: WidgetStateProperty.all(Colors.black),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),

        // 7. Date & Time Pickers
        datePickerTheme: DatePickerThemeData(
          backgroundColor: const Color(0xFF1A2232),
          headerBackgroundColor: const Color(0xFF121824),
          headerForegroundColor: const Color(0xFFE5BA73),
          yearStyle: const TextStyle(color: Color(0xFFE5BA73)),
          dayStyle: const TextStyle(color: Colors.white),
          weekdayStyle: const TextStyle(color: Color(0xFF8A94A6)),
          dayForegroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.black;
            if (states.contains(WidgetState.disabled)) return Colors.white30;
            return Colors.white;
          }),
          dayBackgroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFFE5BA73);
            return Colors.transparent;
          }),
          todayForegroundColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.black;
            return const Color(0xFFE5BA73);
          }),
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFF8A94A6)),
          confirmButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFFE5BA73)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: const Color(0xFF1A2232),
          hourMinuteTextColor: Colors.white,
          hourMinuteColor: const Color(0xFF121824),
          dialBackgroundColor: const Color(0xFF121824),
          dialHandColor: const Color(0xFFE5BA73),
          dialTextColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.black;
            return Colors.white;
          }),
          entryModeIconColor: const Color(0xFFE5BA73),
          cancelButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFF8A94A6)),
          confirmButtonStyle: TextButton.styleFrom(foregroundColor: const Color(0xFFE5BA73)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      // 設定起始畫面：如果已完成登入邏輯可以直接顯示 LoginScreen()，否則亦可改為 HomePage()
      home: const LoginScreen(),
    );
  }
}