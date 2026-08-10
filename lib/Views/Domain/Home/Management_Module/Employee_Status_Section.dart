import 'dart:typed_data';
import 'package:flutter/material.dart';

class EmployeeStatusSection extends StatelessWidget {
  final int workingCount;
  final List<Map<String, dynamic>> teamMembers;
  final bool isLoading;
  final Function(BuildContext context, Map<String, dynamic> member, bool isWorking) onShowEmployeeDetails;

  const EmployeeStatusSection({
    super.key,
    required this.workingCount,
    required this.teamMembers,
    required this.isLoading,
    required this.onShowEmployeeDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('員工狀態', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('$workingCount / ${teamMembers.length} ', style: const TextStyle(color: Color(0xFFE5BA73), fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        isLoading
            ? const SizedBox(
                height: 64,
                child: Center(child: CircularProgressIndicator(color: Color(0xFFE5BA73))), // 載入中動畫
              )
            : teamMembers.isEmpty
                ? const SizedBox(
                    height: 64,
                    child: Center(child: Text('目前團隊無成員', style: TextStyle(color: Color(0xFF8A94A6)))),
                  )
                : SizedBox(
                    height: 64, // 增加一點高度容納卡片框
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: teamMembers.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final member = teamMembers[index];
                        final isWorking = member['isWorking'] == true;
                        String avatarChar = member['name'].toString().isNotEmpty ? member['name'].toString().substring(0, 1) : '?';
                        final Uint8List? pictureBytes = member['pictureBytes'];
                        
                        return GestureDetector(
                          onTap: () => onShowEmployeeDetails(context, member, isWorking),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2232), // 獨立深色卡片
                              borderRadius: BorderRadius.circular(32), // 膠囊圓角
                              border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isWorking ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                  backgroundImage: pictureBytes != null ? MemoryImage(pictureBytes) : null,
                                  child: pictureBytes == null ? Text(avatarChar, style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)) : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      isWorking ? '施工中' : '待命',
                                      style: TextStyle(color: isWorking ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}