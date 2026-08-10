import 'package:flutter/material.dart';
import '../../../../API/Subscribe_api.dart';

/// 封裝創建團隊邏輯和 UI 的動作類別。
/// 透過回呼函數與父 Widget 溝通，更新狀態和顯示訊息。
class CreateTeamAction {
  final String? userId; // 當前使用者的 ID
  final Function(String) onSaveSelectedTeam; // 回呼函數：儲存新創建的團隊為活躍團隊
  final VoidCallback onTeamsUpdated; // 回呼函數：通知父 Widget 重新載入團隊列表
  final Function(String) onError; // 回呼函數：顯示錯誤訊息
  final Function(bool) onSetLoadingTeams; // 回呼函數：更新父 Widget 的載入狀態

  CreateTeamAction({
    required this.userId,
    required this.onSaveSelectedTeam,
    required this.onTeamsUpdated,
    required this.onError,
    required this.onSetLoadingTeams,
  });

  /// 執行創建新團隊的 API 請求。
  Future<void> _createNewTeam(String teamName, BuildContext context) async {
    if (userId == null) {
      onError('無法取得使用者資訊，請重新登入');
      return;
    }
    onSetLoadingTeams(true); // 通知父 Widget 進入載入狀態

    try {
      final result = await SubscriptionApiService.createTeam(
        generatorUUID: userId!,
        teamName: teamName,
      );

      if (result.$1 == null) {
        // 自動將剛創建好的團隊設為當前選中團隊
        if (result.$2 != null) {
          await onSaveSelectedTeam(result.$2!.teamUUID);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('團隊建立成功！'), duration: Duration(seconds: 2)),
        );
        onTeamsUpdated(); // 通知父 Widget 重新整理團隊列表
      } else {
        onError(result.$1!);
      }
    } catch (e) {
      onError('網路發生錯誤: $e');
    } finally {
      onSetLoadingTeams(false); // 通知父 Widget 結束載入狀態
    }
  }

  /// 顯示創建團隊的對話框。
  void showCreateTeamDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2532),
        title: const Text('建立新團隊', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '輸入團隊名稱',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE5BA73))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await _createNewTeam(name, context);
              }
            },
            child: const Text('建立', style: TextStyle(color: Color(0xFFE5BA73))),
          ),
        ],
      ),
    );
  }
}