import 'package:flutter/material.dart';
import '../../../../API/Subscribe_api.dart';

class ManageSubscriptionDialog extends StatefulWidget {
  final String teamUUID;
  final String teamName;
  final VoidCallback onSubscriptionSuccess;

  const ManageSubscriptionDialog({
    super.key,
    required this.teamUUID,
    required this.teamName,
    required this.onSubscriptionSuccess,
  });

  // 提供一個靜態方法方便外部直接呼叫開啟對話框
  static void show(
    BuildContext context, {
    required String teamUUID,
    required String teamName,
    required VoidCallback onSubscriptionSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 設定透明背景，讓內部自己長成圓角視窗
      elevation: 0, // 移除預設陰影
      builder: (ctx) => Padding(
        // 加入左右與底部的留白，讓它看起來像一個懸浮的視窗 (Dialog)，並能避開鍵盤
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, // 距離底部 24px，且會隨鍵盤浮動
          left: 20, // 距離左右 20px
          right: 20,
        ),
        child: ManageSubscriptionDialog(
          teamUUID: teamUUID,
          teamName: teamName,
          onSubscriptionSuccess: onSubscriptionSuccess,
        ),
      ),
    );
  }

  @override
  State<ManageSubscriptionDialog> createState() => _ManageSubscriptionDialogState();
}

class _ManageSubscriptionDialogState extends State<ManageSubscriptionDialog> {
  String _selectedPlan = '7day';
  final TextEditingController _licenseController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> plans = [
      {'value': '7day', 'title': '7天方案', 'sub': '基礎體驗，適合短期測試'},
      {'value': '14day', 'title': '14天方案', 'sub': '進階體驗，完整功能試用'},
      {'value': '1month', 'title': '1個月方案', 'sub': '單月訂閱，彈性無負擔'},
      {'value': '3month', 'title': '3個月方案', 'sub': '季繳優惠，穩定使用'},
      {'value': '6month', 'title': '6個月方案', 'sub': '半年度計畫，超值首選'},
      {'value': '1year', 'title': '1年方案', 'sub': '年度尊榮，最划算投資'},
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 24.0), // 距離上方留白
        decoration: BoxDecoration(
          color: const Color(0xFF1E2532),
          borderRadius: BorderRadius.circular(24), // 四周皆為圓角，看起來像獨立的對話框
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 4),
          ],
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(), // 保留此屬性讓下滑手勢能傳遞並觸發關閉
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 頂部拖曳指示條，提示使用者可以往下拉關閉
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 標題與關閉按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('升級專屬方案', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
                      const Icon(Icons.shield_outlined, color: Color(0xFFE5BA73), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('目前團隊：${widget.teamName}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 方案選擇條列 (Premium List)
                const Text('選擇方案效期', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isSelected = _selectedPlan == plan['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan['value']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE5BA73).withOpacity(0.15) : const Color(0xFF121824),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE5BA73) : Colors.white.withOpacity(0.05),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6),
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(plan['title'], style: TextStyle(color: isSelected ? const Color(0xFFE5BA73) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(plan['sub'], style: TextStyle(color: isSelected ? const Color(0xFFE5BA73).withOpacity(0.8) : const Color(0xFF8A94A6), fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // 授權碼輸入框
                const Text('專屬授權碼 (由本公司提供)', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _licenseController,
                  style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5),
                  decoration: InputDecoration(
                    hintText: '輸入您的授權碼...',
                    hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1.0, fontSize: 14),
                    prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF8A94A6)),
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
                    onPressed: _isSubmitting ? null : _submitSubscription,
                    child: _isSubmitting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('立即開通', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitSubscription() async {
    final licenseKey = _licenseController.text.trim();
    if (licenseKey.isEmpty) {
      setState(() => _errorMessage = '請輸入專屬授權碼');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await SubscriptionApiService.subscribe(
      teamUUID: widget.teamUUID,
      subscriptionPlan: _selectedPlan,
      licenseKey: licenseKey,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.$1 == null) {
      Navigator.pop(context);
      widget.onSubscriptionSuccess();
    } else {
      setState(() => _errorMessage = result.$1);
    }
  }
}