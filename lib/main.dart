import 'package:flutter/material.dart';
import 'Views/Authenticator/Login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFE5BA73), // 主要金色
          primary: const Color(0xFFE5BA73), 
          secondary: const Color(0xFFC19A5B), // 金色漸層輔助
          surface: const Color(0xFF1A2232), // 卡片底色
        ),
        scaffoldBackgroundColor: const Color(0xFF121824), // 深底色
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121824), // 頂部導航列深色
          foregroundColor: Color(0xFFFFFFFF), // 白色標題
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
