import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/saved_model.dart';
import '../widgets/stock_card.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  static const _kNavy = Color(0xFF0A1628);

  bool _isKoreanCode(String code) =>
      code.isNotEmpty && RegExp(r'^[0-9]').hasMatch(code);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<SavedModel>();
    final items = model.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Icon(Icons.bookmark_rounded, size: 20, color: _kNavy),
            const SizedBox(width: 8),
            const Text('저장한 종목',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _kNavy)),
            if (items.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text('${items.length}',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF8A8FA8))),
            ],
          ],
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded,
                      size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    '저장한 종목이 없습니다.\n카드의 북마크를 눌러 저장하세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFFADB3C8), height: 1.5),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return StockCard(
                  item: item,
                  isKorean: _isKoreanCode(item.code),
                );
              },
            ),
    );
  }
}
