import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_item.dart';

class ApiService {
  static const String baseUrl = 'https://stock-dashboard-0atp.onrender.com';
  static const String _appApiKey = 'SP-a4f8c2e1d9b3';

  /// 시총 상위 종목: Claude 웹 검색으로 직접 조회 (스트리밍)
  static Stream<StockItem> fetchStocks({
    required String country,
    required String sector,
    required String lang,
  }) {
    final sectorStr = sector == 'all' ? '' : '$sector 섹터 ';
    final countryStr = country == 'kr' ? '한국' : '미국';
    final krwNote = (country == 'kr' && lang == 'ko')
        ? ' 시총과 주가는 원화(₩)로 표시하세요(예: ₩2,450조, ₩85,000).'
        : '';
    final prompt = '$countryStr $sectorStr시가총액 상위 20개 종목을 웹에서 검색해서 '
        '최근 이슈와 투자 포인트를 정리해주세요. '
        '시총·현재가·등락률을 포함하세요. 정확히 20개 항목을 반환하세요.$krwNote';

    return _searchStream(prompt: prompt, lang: lang, useWebsearch: true);
  }

  /// 웹 검색 기반 커스텀 검색 (ETF, 레버리지 등) — 스트리밍
  static Stream<StockItem> search({
    required String prompt,
    required String lang,
  }) =>
      _searchStream(prompt: prompt, lang: lang, useWebsearch: true);

/// 스트리밍 중 괄호 카운팅으로 완성된 item 객체를 실시간 추출
  static Stream<StockItem> _searchStream({
    required String prompt,
    required String lang,
    required bool useWebsearch,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/search'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['X-API-Key'] = _appApiKey;
      request.body = jsonEncode({
        'prompt': prompt,
        'lang': lang,
        'use_websearch': useWebsearch,
      });

      final response = await client.send(request);
      if (response.statusCode != 200) throw Exception('Search failed');

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        // 버퍼에서 완성된 item 객체를 순서대로 추출
        while (true) {
          final result = _extractNextItem(buffer);
          if (result == null) break;
          buffer = result.$2;
          try {
            yield StockItem.fromJson(result.$1);
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  /// 버퍼에서 완성된 stock item JSON 객체 하나를 추출.
  /// "name" + "summary" 키를 가진 가장 바깥 {…}을 찾아 파싱.
  /// 반환값: (parsed map, 나머지 버퍼) 또는 null (아직 완성 안 됨)
  static (Map<String, dynamic>, String)? _extractNextItem(String s) {
    int searchFrom = 0;

    while (true) {
      // "name" 키가 있는 위치를 탐색
      final nameIdx = s.indexOf('"name"', searchFrom);
      if (nameIdx == -1) return null;

      // "name" 앞의 여는 { 찾기 (직전 {)
      int braceStart = -1;
      for (int i = nameIdx - 1; i >= 0; i--) {
        final c = s[i];
        if (c == '{') {
          braceStart = i;
          break;
        }
        if (c == '[' || c == ']' || c == '}') break;
      }
      if (braceStart == -1) {
        searchFrom = nameIdx + 1;
        continue;
      }

      // 매칭되는 닫는 } 찾기 (중첩 고려)
      final braceEnd = _matchingBrace(s, braceStart);
      if (braceEnd == -1) return null; // 아직 완성 안 됨

      final candidate = s.substring(braceStart, braceEnd + 1);
      try {
        final json = jsonDecode(candidate) as Map<String, dynamic>;
        // stock item 확인: name + summary 둘 다 있어야 함
        if (json.containsKey('name') && json.containsKey('summary')) {
          return (json, s.substring(braceEnd + 1));
        }
      } catch (_) {}

      searchFrom = nameIdx + 1;
    }
  }

  /// start 위치의 { 에 매칭되는 } 인덱스 반환 (-1 = 아직 없음)
  static int _matchingBrace(String s, int start) {
    int depth = 0;
    bool inStr = false;
    bool esc = false;

    for (int i = start; i < s.length; i++) {
      if (esc) {
        esc = false;
        continue;
      }
      final c = s[i];
      if (c == '\\' && inStr) {
        esc = true;
        continue;
      }
      if (c == '"') {
        inStr = !inStr;
        continue;
      }
      if (inStr) continue;

      if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1; // 아직 닫히지 않음
  }
}
