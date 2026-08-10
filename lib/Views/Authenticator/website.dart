import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsiteLinks extends StatelessWidget {
  const WebsiteLinks({super.key});

  @override
  Widget build(BuildContext context) {
    // 最底部的官網與 LINE 連結 (固定於底部)
    return Positioned(
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
            child: Image.asset(
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
              final Uri url = Uri.parse('https://www.youtube.com/@ezid_tw'); // 👈 請把這裡換成你們的 YouTube 網址

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
            child: const FaIcon(
              FontAwesomeIcons.youtube,
              color: Color(0xFFFF0000), // YouTube 的經典紅色
              size: 36,
            ),
          ),
          const SizedBox(width: 48), // 拉開兩個圖示的距離
          GestureDetector(
            onTap: () async {
              // 1. 設定你要前往的網址
              // 注意：原始程式碼此處的 URL 仍為 ezid.com.tw，但圖示為 LINE。
              // 建議替換為實際的 LINE 官方帳號連結，例如：https://line.me/R/ti/p/@your_line_id
              final Uri url = Uri.parse('https://line.me/ti/p/@ezid_tw'); // 👈 請把這裡換成你們的 LINE 官方帳號網址

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
            child: const FaIcon(
              FontAwesomeIcons.line,
              color: Color(0xFF00C300), // 這是 LINE 官方的經典綠色
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}