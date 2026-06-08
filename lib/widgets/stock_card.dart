import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/stock_item.dart';

class StockCard extends StatelessWidget {
  final StockItem item;
  final bool isKorean;

  const StockCard({super.key, required this.item, required this.isKorean});

  String get _naverUrl => item.code.isNotEmpty
      ? 'https://finance.naver.com/item/main.naver?code=${item.code}'
      : '';

  String get _yahooUrl => item.code.isNotEmpty
      ? 'https://finance.yahoo.com/quote/${item.code}'
      : '';

  Future<({String url, String label})> _resolveLink() async {
    if (!isKorean) return (url: _yahooUrl, label: 'Yahoo Finance');
    return (url: _naverUrl, label: '네이버 증권');
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _badgeColor() {
    switch (item.badgeType) {
      case 'new':  return const Color(0xFF185FA5);
      case 'lev':  return const Color(0xFF006B65);
      case 'down': return Colors.red.shade700;
      default:     return const Color(0xFF3B6D11);
    }
  }

  Color _badgeBg() {
    switch (item.badgeType) {
      case 'new':  return const Color(0xFFE6F1FB);
      case 'lev':  return const Color(0xFFDFF6F5);
      case 'down': return Colors.red.shade50;
      default:     return const Color(0xFFEAF3DE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor    = Colors.grey.shade200;
    final codeChipBg     = Colors.grey.shade100;
    final codeChipText   = Colors.grey.shade700;
    final summaryColor   = Colors.grey.shade600;
    final metricLabel    = Colors.grey.shade500;
    final dividerColor   = Colors.grey.shade100;

    final hasLink = item.code.isNotEmpty;

    return GestureDetector(
      onLongPress: item.code.isEmpty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: item.code));
              await HapticFeedback.mediumImpact();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.copy_rounded,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('${item.code} 복사됨',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    backgroundColor: const Color(0xFF0A1628),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 카드 본문 ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더: 종목명 + 코드칩 + 배지
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.black87),
                              ),
                              if (item.code.isNotEmpty) ...[
                                const TextSpan(text: '  '),
                                WidgetSpan(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: codeChipBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(item.code,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: codeChipText)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (item.badge.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _badgeBg(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.badge,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _badgeColor())),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 요약
                  Text(item.summary,
                      style: TextStyle(fontSize: 12, color: summaryColor)),
                  // 지표
                  if (item.metrics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: item.metrics.map((m) {
                        Color? color;
                        if (m.positive == true) color = Colors.green.shade700;
                        if (m.positive == false) color = Colors.red.shade700;
                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label,
                                  style: TextStyle(
                                      fontSize: 10, color: metricLabel)),
                              const SizedBox(height: 2),
                              Text(m.value,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: color ?? Colors.black87)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // ── 하단 링크 버튼 (나무증권 or 네이버/Yahoo) ────────────────
            if (hasLink) ...[
              Divider(height: 1, thickness: 1, color: dividerColor),
              FutureBuilder<({String url, String label})>(
                future: _resolveLink(),
                builder: (context, snapshot) {
                  final label = snapshot.data?.label ??
                      (isKorean ? '네이버 증권' : 'Yahoo Finance');
                  final url   = snapshot.data?.url ?? '';

                  const linkColor = Color(0xFF006B65);
                  const linkBg    = Color(0xFFDFF6F5);

                  return InkWell(
                    onTap: url.isEmpty ? null : () => _open(url),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: linkBg,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 13, color: linkColor),
                          const SizedBox(width: 5),
                          Text('$label에서 보기',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: linkColor)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
