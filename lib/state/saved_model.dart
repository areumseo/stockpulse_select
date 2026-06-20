import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_item.dart';

/// 저장한 종목(관심 목록) — 기기 로컬에 저장(snapshot). 로그인 불필요.
class SavedModel extends ChangeNotifier {
  static const _key = 'saved_items_v1';

  List<StockItem> _items = [];
  List<StockItem> get items => List.unmodifiable(_items);

  bool isSaved(String code) =>
      code.isNotEmpty && _items.any((e) => e.code == code);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _items = raw
        .map((s) {
          try {
            return StockItem.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<StockItem>()
        .toList();
    notifyListeners();
  }

  Future<void> toggle(StockItem item) async {
    if (item.code.isEmpty) return;
    if (isSaved(item.code)) {
      _items = _items.where((e) => e.code != item.code).toList();
    } else {
      _items = [item, ..._items]; // 최근 저장이 위로
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String code) async {
    _items = _items.where((e) => e.code != code).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, _items.map((i) => jsonEncode(i.toJson())).toList());
  }
}
