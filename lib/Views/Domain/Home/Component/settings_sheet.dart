import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Authenticator/Login.dart';
import '../Setting/EditRegisterInfo.dart';

class SettingsBottomSheet extends StatelessWidget {
  final String userName;
  final String? userPictureBase64;
  final String? userCompany;
  final String? userPosition;
  final String? userPhone;
  final bool isProfileComplete;
  final Map<String, dynamic>? fullUserData;
  final BuildContext parentContext; // Context from HomePage to navigate from
  final VoidCallback? onDataUpdated; // 回呼函數：當編輯完成返回時通知首頁更新資料

  const SettingsBottomSheet({
    super.key,
    required this.userName,
    this.userPictureBase64,
    this.userCompany,
    this.userPosition,
    this.userPhone,
    required this.isProfileComplete,
    this.fullUserData,
    required this.parentContext,
    this.onDataUpdated,
  });

  @override
  Widget build(BuildContext context) { // 'context' here is the sheetContext
    return SafeArea(
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF121824),
                  backgroundImage: userPictureBase64 != null && userPictureBase64!.isNotEmpty
                      ? MemoryImage(base64Decode(userPictureBase64!.split(',').last.replaceAll(RegExp(r'\s+'), '')))
                      : null,
                  child: userPictureBase64 == null || userPictureBase64!.isEmpty
                      ? const Icon(Icons.person_outline, color: Color(0xFFE5BA73), size: 36)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)]),
                              borderRadius: BorderRadius.circular(16), // 圈圈圓弧柱狀橫長體
                            ),
                            child: const Text('已訂閱', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(userCompany == null || userCompany!.isEmpty || userCompany == '.') ? '尚未填寫公司' : userCompany} • '
                        '${(userPosition == null || userPosition!.isEmpty || userPosition == '.') ? '尚未填寫職務' : userPosition}',
                        style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14),
                      ),
                      if (userPhone != null && userPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(userPhone!, style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13)),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Color(0xFFE5BA73)),
            title: const Text('編輯個人資料', style: TextStyle(color: Colors.white)),
            onTap: () {
              if (!isProfileComplete) {
                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('請完善您的個人資料！'), duration: Duration(seconds: 1))); // 顯示2秒
              }
              Navigator.pop(context); // Close the bottom sheet
              Navigator.push(parentContext, MaterialPageRoute(builder: (ctx) => EditProfileScreen(userData: fullUserData))).then((_) {
                if (onDataUpdated != null) onDataUpdated!(); // 編輯完成返回後，觸發更新
              });
            },
            trailing: !isProfileComplete ? const Icon(Icons.error, color: Colors.red, size: 20) : null,
          ),


          ListTile(
            leading: const Icon(Icons.subscriptions, color: Color(0xFFE5BA73)),
            title: const Text('管理我的訂閱', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // 關閉底部選單
              Navigator.push(parentContext, MaterialPageRoute(builder: (ctx) => EditProfileScreen(userData: fullUserData))).then((_) {
                if (onDataUpdated != null) onDataUpdated!(); // 訂閱管理完成返回後，觸發更新
              });
            },
            trailing: !isProfileComplete ? const Icon(Icons.error, color: Colors.red, size: 20) : null,
          ),



          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('登出', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              Navigator.pop(context); // Close the bottom sheet
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_id');
              
              if (!parentContext.mounted) return;
              Navigator.pushAndRemoveUntil(
                parentContext,
                MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}