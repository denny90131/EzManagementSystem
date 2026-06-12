import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Component/NavBar.dart'; // 修正為正確的導航框架路徑
import '../../Services/Authenticator/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isCheckingAuth = true; // 新增：控制初始驗證狀態，避免直接顯示登入表單
  bool _rememberMe = false; // 控制記住我的勾選狀態
  bool _isPasswordVisible = false; // 控制密碼是否顯示
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _loadSavedCredentials(); // 初始化時嘗試讀取本機儲存的帳密
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    // 檢查是否有儲存 user_id (代表上次未登出)
    if (userId != null && userId.isNotEmpty) {
      try {
        final userData = await ApiService.getUserById(userId);
        final status = await ApiService.getCompletionStatus(userId);
        if (!mounted) return;
        if (userData != null) {
          if (status != null) {
            userData['isProfileComplete'] = status['isComplete']; // 將進度狀態塞入 userData
          }
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => MainScreen(userData: userData)),
          );
          return; // 跳轉後結束執行
        }
      } catch (e) {
        // 背景登入失敗，忽略並讓使用者手動登入
      }
    }

    // 如果沒有 UID 或自動登入失敗，則結束驗證狀態並顯示登入表單
    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
        
        final rememberMe = prefs.getBool('remember_me') ?? false;
        if (rememberMe) {
          _rememberMe = true;
          phoneController.text = prefs.getString('saved_phone') ?? '';
          passwordController.text = prefs.getString('saved_password') ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // 呼叫 ApiService 的登入方法
        final (errorMessage, userData) = await ApiService.loginUser(
            phoneController.text.trim(), passwordController.text.trim());

        if (!mounted) return;

        if (errorMessage == null && userData != null) {
          // 登入成功後，根據「記住我」的狀態來儲存或清除本機帳密
          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setString('saved_phone', phoneController.text.trim());
            await prefs.setString('saved_password', passwordController.text.trim());
            await prefs.setBool('remember_me', true);
          } else {
            await prefs.remove('saved_phone');
            await prefs.remove('saved_password');
            await prefs.setBool('remember_me', false);
          }

          // 儲存 user_id 以供後續 API (如編輯個人資料) 使用
          final String? uid = userData['index']?.toString() ?? userData['Index']?.toString();
          Map<String, dynamic> fullUserData = Map<String, dynamic>.from(userData);
          
          if (uid != null) {
            await prefs.setString('user_id', uid);
            
            // 確定取得最完整的資料與進度後再進入主畫面
            final fetchedData = await ApiService.getUserById(uid);
            if (fetchedData != null) {
              fullUserData = fetchedData;
            }
            final status = await ApiService.getCompletionStatus(uid);
            if (status != null) {
              fullUserData['isProfileComplete'] = status['isComplete'];
            }
          }
          
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('登入成功！歡迎 ${fullUserData['name'] ?? userData['name']}')));
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => MainScreen(userData: fullUserData)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('登入失敗：${errorMessage ?? '未知錯誤'}')));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('發生未預期的錯誤：$e')));
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool isRequired = false,
    Widget? suffixIcon,
    FocusNode? focusNode,
  }) {
    final bool isFocused = focusNode?.hasFocus ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isFocused)
              BoxShadow(
                color: const Color(0xFFE5BA73).withOpacity(0.2), // 聚焦時的金色發光
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w500, fontSize: 16),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return '請輸入$label';
            }
            return null;
          },
          decoration: InputDecoration(
            label: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (isRequired)
                    const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE5BA73))),
                ],
              ),
              style: TextStyle(color: isFocused ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)), // 半透明灰
            ),
            prefixIcon: icon != null ? Icon(icon, color: isFocused ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)) : null,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5BA73), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFF1A2232), // 不透明卡片底色
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果還在檢查是否有登入過，先顯示全螢幕的載入中畫面 (Splash Screen 風格)
    if (_isCheckingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFF121824),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: ExactAssetImage('assets/images/ez_icon.png', scale: 2.0),
                fit: BoxFit.cover,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFFE5BA73)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 深底色
      resizeToAvoidBottomInset: false, // 避免鍵盤彈出時壓縮畫面，使底部圖示保持固定
      body: Stack(
        children: [
          // 金色微光渲染層
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0xFFE5BA73).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 全螢幕暗色意象圖
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/login_bg.png'), // 暗色建築鋼骨線條背景
                  fit: BoxFit.cover,
                  opacity: 0.15, // 隱約的高解析質感
                  onError: (exception, stackTrace) {
                    // 找不到圖片時靜默忽略，避免整個登入畫面崩潰
                  },
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter, // 讓整體內容靠上對齊
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 頂部 Logo (無框、放大)
                          const Image(
                            image: ExactAssetImage('assets/images/ez_icon.png', scale: 2.0),
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '易派工',
                            style: TextStyle(
                              fontSize: 24, // 字體變小
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Comic Sans MS', // 漫畫風字體
                              color: Color(0xFFFFFFFF),
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 30), // 拉開與表單的距離
                          
                          // 移除外層卡片，讓元件直接置於背景之上
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField(
                                  phoneController, 
                                  '帳號', 
                                  icon: Icons.person_outline, // 線性細線條圖標
                                  isRequired: true,
                                  focusNode: _phoneFocusNode,
                                ),
                                _buildTextField(
                                  passwordController, 
                                  '密碼', 
                                  icon: Icons.lock_outline, // 線性細線條圖標
                                  obscureText: !_isPasswordVisible, 
                                  isRequired: true,
                                  focusNode: _passwordFocusNode,
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF8A94A6)),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                // 記住我
                                Row(
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        unselectedWidgetColor: const Color(0xFF8A94A6),
                                      ),
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: const Color(0xFFE5BA73), // 主要金色
                                        checkColor: Colors.black, // 黑字
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const Text('記住我', style: TextStyle(color: Color(0xFF8A94A6))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // 登入按鈕 (滿版)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)], // 金色漸層 (Primary)
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent, // 背景透明以顯示漸層
                                      shadowColor: Colors.transparent, // 避免與外部 BoxShadow 衝突
                                      foregroundColor: Colors.black, // 黑字
                                      padding: const EdgeInsets.symmetric(vertical: 18), 
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                        : const Text('登入', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                // 註冊文字連結
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('還沒有帳號？', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 15)),
                                    TextButton(
                                      onPressed: () {
                                    Navigator.push(context, CupertinoPageRoute(builder: (context) => const RegisterScreen()));
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('立即註冊', style: TextStyle(color: Color(0xFFE5BA73), fontSize: 15, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 100), // 新增底部留白，避免內容被最下方的社群圖示遮擋
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 最底部的官網與 LINE 連結 (固定於底部)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    // 1. 設定你要前往的網址
                    final Uri url = Uri.parse('https://www.ezid.com.tw'); // 👈 請把這裡換成你們的官網網址

                    // 2. 呼叫 launchUrl 來開啟網頁
                    // mode: LaunchMode.externalApplication 代表使用手機系統預設的瀏覽器 (Chrome/Safari) 開啟
                    try {
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        // 如果因為某些原因打不開，可以在這裡印出錯誤或顯示 SnackBar
                        debugPrint('無法開啟網址: $url');
                      }
                    } catch (e) {
                      debugPrint('發生錯誤: $e');
                    }
                  },
                  child: 
                    Image.asset(
                      'assets/images/ezibits_logo.png', // 這是你提供的官網圖示
                      width: 45,
                      height: 45,
                      fit: BoxFit.contain,
                    ),
                ),
                const SizedBox(width: 48), // 拉開兩個圖示的距離
                GestureDetector(
                  onTap: () async {
                    // 1. 設定你要前往的網址
                    final Uri url = Uri.parse('https://www.youtube.com/@ezid_tw'); // 👈 請把這裡換成你們的官網網址

                    // 2. 呼叫 launchUrl 來開啟網頁
                    // mode: LaunchMode.externalApplication 代表使用手機系統預設的瀏覽器 (Chrome/Safari) 開啟
                    try {
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        // 如果因為某些原因打不開，可以在這裡印出錯誤或顯示 SnackBar
                        debugPrint('無法開啟網址: $url');
                      }
                    } catch (e) {
                      debugPrint('發生錯誤: $e');
                    }
                  },
                  child: 
                  const FaIcon(
                    FontAwesomeIcons.youtube,
                    color: const Color(0xFFFF0000), // 這是 FB 的經典藍色 
                    size: 36,
                  )
                ),
                const SizedBox(width: 48), // 拉開兩個圖示的距離
                GestureDetector(
                  onTap: () async {
                    // 1. 設定你要前往的網址
                    final Uri url = Uri.parse('https://www.ezid.com.tw'); // 👈 請把這裡換成你們的官網網址

                    // 2. 呼叫 launchUrl 來開啟網頁
                    // mode: LaunchMode.externalApplication 代表使用手機系統預設的瀏覽器 (Chrome/Safari) 開啟
                    try {
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        // 如果因為某些原因打不開，可以在這裡印出錯誤或顯示 SnackBar
                        debugPrint('無法開啟網址: $url');
                      }
                    } catch (e) {
                      debugPrint('發生錯誤: $e');
                    }
                  },
                  child: 
                  // 在你的按鈕或 Row 裡面直接這樣使用
                  const FaIcon(
                    FontAwesomeIcons.line,
                    color: const Color(0xFF00C300), // 這是 LINE 官方的經典綠色 
                    size: 36,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}