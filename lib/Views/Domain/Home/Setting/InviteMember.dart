import 'package:flutter/material.dart';

class InviteMemberDialog extends StatefulWidget {
  final String teamUUID;
  final String teamName;

  const InviteMemberDialog({
    super.key,
    required this.teamUUID,
    required this.teamName,
  });

  // 提供一個靜態方法方便外部直接呼叫開啟對話框
  static void show(
    BuildContext context, {
    required String teamUUID,
    required String teamName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => InviteMemberDialog(
        teamUUID: teamUUID,
        teamName: teamName,
      ),
    );
  }

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final TextEditingController _contactController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2532),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 4),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 標題與關閉按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('邀請新成員', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // 團隊標示牌
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121824),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.group_add_outlined, color: Color(0xFFE5BA73), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('邀請至：${widget.teamName}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 輸入框
                const Text('聯絡方式', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _contactController,
                  style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.0),
                  decoration: InputDecoration(
                    hintText: '輸入手機號碼或信箱...',
                    hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1.0, fontSize: 14),
                    prefixIcon: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF8A94A6)),
                    filled: true,
                    fillColor: const Color(0xFF121824),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5BA73))),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ],
                const SizedBox(height: 32),

                // 確認送出按鈕 (滿版金色漸層)
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submitInvite,
                    child: _isSubmitting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('發送邀請', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitInvite() async {
    final contactInfo = _contactController.text.trim();
    if (contactInfo.isEmpty) {
      setState(() => _errorMessage = '請輸入對方的手機號碼或信箱');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // TODO: 之後請在這裡呼叫真實的邀請 API
    // final result = await TeamApiService.inviteMember(teamUUID: widget.teamUUID, contact: contactInfo);
    
    // 目前先模擬等待 1 秒鐘
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // 成功後關閉並顯示提示
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('邀請發送成功！')));
  }
}