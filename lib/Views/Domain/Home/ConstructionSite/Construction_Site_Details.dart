import 'package:flutter/material.dart';
import 'details_construction.dart'; // 引入工地詳情頁面

class ConstructionSiteList extends StatelessWidget {
  final List<Map<String, dynamic>> sites;
  final List<Map<String, dynamic>> filteredSites;
  final TextEditingController searchController;
  final bool isLoading;

  const ConstructionSiteList({
    super.key,
    required this.sites,
    required this.filteredSites,
    required this.searchController,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 6. 即將到來案件 (點擊進入詳細頁面)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('案件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('共 ${filteredSites.length} 件', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 14)),
          ],
        ),
        const SizedBox(height: 16),
        // 搜尋框
        TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '搜尋工地名稱、地址或業主...',
            hintStyle: const TextStyle(color: Color(0xFF8A94A6)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF8A94A6)),
            suffixIcon: searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF8A94A6)), onPressed: () => searchController.clear()) : null,
            filled: true,
            fillColor: const Color(0xFF1A2232),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        
        // 工地列表
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator(color: Color(0xFFE5BA73))))
        else if (filteredSites.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 80),
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(color: const Color(0xFF1A2232), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(sites.isEmpty ? '目前尚無工地案件' : '找不到符合條件的案件', style: const TextStyle(color: Color(0xFF8A94A6)))),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSites.length,
              itemBuilder: (context, index) {
                final site = filteredSites[index];
                final siteUUID = site['siteUUID']?.toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2232),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5BA73).withOpacity(0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: siteUUID != null // 確保 siteUUID 存在才可點擊
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CaseDetailPage(site: site)), // 將整個 site map 傳遞過去
                              );
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(site['siteName'] ?? '未命名工地', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8A94A6)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on, size: 20, color: Colors.red.shade400),
                                const SizedBox(width: 12),
                                Expanded(child: Text(site['siteAddress'] ?? '無地址資訊', style: const TextStyle(color: Color(0xFF8A94A6), height: 1.4, fontSize: 14))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.person, size: 20, color: Colors.blue.shade400),
                                const SizedBox(width: 12),
                                Expanded(child: Text('業主: ${site['siteOwner'] ?? '-'}', style: const TextStyle(color: Color(0xFF8A94A6), height: 1.4, fontSize: 14))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // 由於 _buildCaseInfoRow 已被移除，這裡直接展開 Row 的實作
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.note_alt_outlined, size: 20, color: Colors.green.shade400),
                                const SizedBox(width: 12),
                                Expanded(child: Text('備註: ${site['note'] ?? '-'}', style: const TextStyle(color: Color(0xFF8A94A6), height: 1.4, fontSize: 14))),
                              ],
                            ),
                          ],
                        ),
                      ),
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
