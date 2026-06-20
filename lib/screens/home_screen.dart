import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../api/api_service.dart';
import '../models/stock_item.dart';
import '../widgets/stock_card.dart';

// ── Theme colors ─────────────────────────────────────────────────────────────
const _kNavy    = Color(0xFF0A1628);
const _kNavyMid = Color(0xFF0F2040);
const _kCyan    = Color(0xFF00D4CC);
const _kCyanDim = Color(0x4400D4CC);
// Dark mode banner: muted/desaturated cyan
const _kCyanMuted = Color(0xFF4A9DA8);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _lang = 'ko';
  int _countryIndex = 0;
  int _tabIndex = 0;

  String _krSector = 'all';
  String _krEtfType = '신규 상장 ETF';
  String _krEtfPeriod = '최근 1개월';
  String _krEtfKeyword = '';
  String _krLevType = '전체';
  String _krLevSector = '전체';

  String _usSector = 'all';
  String _usEtfType = '지수 추종 ETF';
  String _usEtfPeriod = '최근 1개월';
  String _usEtfKeyword = '';
  String _usLevType = '2x · 3x 전체';
  String _usLevSector = '전체';
  String _usSort = '수익률 높은 순';

  List<StockItem> _items = [];
  bool _loading = false;
  bool _refreshing = false;
  String? _error;
  bool _searchedEmpty = false; // 검색은 정상 완료됐지만 결과가 0개
  DateTime? _lastFetched;
  int _searchGen = 0;

  final ScrollController _scrollController = ScrollController();

  // 탭별 결과 캐시 — 앱 세션 동안 유지
  static final Map<String, List<StockItem>> _cache = {};

  String get _cacheKey =>
      '${_isKr ? 'kr' : 'us'}_${_tabIndex}_${_isKr ? _krSector : _usSector}';

  bool get _isKr => _countryIndex == 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 앱 시작 시 자동 검색하지 않음 — 사용자가 조건 선택 후 '검색'을 눌러야 실행.
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // 끝에서 80px 이내 + 로딩 중 아닐 때 → 새로고침
    if (pos.pixels >= pos.maxScrollExtent - 80 &&
        _items.isNotEmpty &&
        !_loading &&
        !_refreshing) {
      _search();
    }
  }

  Map<String, String> get t => _lang == 'ko'
      ? {
          'subtitle': '국내·미국 개별주 · ETF · 레버리지 ETF',
          'country_kr': '🇰🇷 한국',
          'country_us': '🇺🇸 미국',
          'tab_stocks': '개별주 시총',
          'tab_etf': 'ETF',
          'tab_lev': '레버리지 ETF',
          'search': '검색',
          'searching': 'Claude가 검색 중...',
          'no_results': '검색 결과가 없습니다.\n다른 조건으로 다시 시도해보세요.',
          'empty_hint': '조건을 선택하고 검색하세요.',
          'sector': '섹터',
          'disclaimer': '⚠️ 투자 참고 목적이며 투자 권유가 아닙니다.',
          'data_source': '출처: companiesmarketcap.com · 조회: ',
        }
      : {
          'subtitle': 'KR & US Stocks · ETFs · Leveraged ETFs',
          'country_kr': '🇰🇷 Korea',
          'country_us': '🇺🇸 US',
          'tab_stocks': 'Stocks (MCap)',
          'tab_etf': 'ETFs',
          'tab_lev': 'Leveraged ETFs',
          'search': 'Search',
          'searching': 'Claude is searching...',
          'no_results': 'No results found.\nTry different conditions.',
          'empty_hint': 'Select filters above and tap Search.',
          'sector': 'Sector',
          'disclaimer': '⚠️ For informational purposes only.',
          'data_source': 'Source: companiesmarketcap.com · As of ',
        };

  Stream<StockItem> _buildStream() {
    return _tabIndex == 0
        ? ApiService.fetchStocks(
            country: _isKr ? 'kr' : 'us',
            sector: _isKr ? _krSector : _usSector,
            lang: _lang,
          )
        : ApiService.search(
            prompt: _buildPrompt(),
            lang: _lang,
          );
  }

  void _cancelSearch() {
    _searchGen++; // 현재 스트림 무효화 → _runStream이 감지하고 return
    setState(() { _loading = false; _refreshing = false; });
  }

  /// 탭·국가 전환 시: 네트워크 호출 없이 앱 캐시만 복원(있으면 즉시 표시).
  /// 캐시가 없으면 빈 화면 → "조건을 선택하고 검색하세요" 힌트 노출.
  /// 실제 검색은 사용자가 '검색' 버튼을 눌렀을 때만 수행한다.
  void _switchContext() {
    _searchGen++; // 진행 중이던 스트림이 있으면 무효화
    final cached = _cache[_cacheKey];
    setState(() {
      _error = null;
      _searchedEmpty = false;
      _loading = false;
      _refreshing = false;
      _items = (cached != null && cached.isNotEmpty) ? List.of(cached) : [];
    });
  }

  Future<void> _search() async {
    final gen = ++_searchGen;
    final key = _cacheKey;
    final cached = _cache[key];

    // ── 캐시 히트: 즉시 표시 + 항상 백그라운드 갱신 ─────────────────────────
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _items = List.of(cached);
        _loading = false;
        _refreshing = true;
        _error = null;
        _searchedEmpty = false;
      });
      await _runStream(gen, key);
      return;
    }

    // ── 캐시 없음: 스피너 → 스트리밍 ───────────────────────────────────────
    setState(() { _loading = true; _refreshing = false; _error = null; _searchedEmpty = false; _items = []; });
    await _runStream(gen, key);
  }

  Future<void> _runStream(int gen, String key) async {
    final freshItems = <StockItem>[];
    try {
      await for (final item in _buildStream()) {
        if (gen != _searchGen) return;
        freshItems.add(item);
        setState(() {
          _items = List.of(freshItems);
          _loading = false;
          _refreshing = true;
          _lastFetched = DateTime.now();
        });
      }
      if (gen == _searchGen) {
        if (freshItems.isNotEmpty) {
          _cache[key] = List.of(freshItems);
          setState(() => _refreshing = false);
        } else if (_items.isEmpty) {
          // 스트림은 정상 완료됐지만 결과가 0개 — 에러가 아니라 "결과 없음"으로 안내
          setState(() => _searchedEmpty = true);
        }
      }
    } catch (e) {
      if (gen != _searchGen) return;
      if (freshItems.isEmpty && _items.isEmpty) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (gen == _searchGen) setState(() { _loading = false; _refreshing = false; });
    }
  }

  String _buildPrompt() {
    const n = '10개';
    if (_isKr) {
      if (_tabIndex == 1) {
        final theme = _krEtfKeyword.isEmpty ? '' : " '$_krEtfKeyword' 관련";
        switch (_krEtfType) {
          case '신규 상장 ETF':
            return '$_krEtfPeriod 내에 KRX에 신규 상장된$theme 국내 ETF $n를 알려주세요. 상장일, 운용사, 투자 테마, 순자산총액, 수익률을 포함하세요.';
          case '꾸준히 수익률 상승':
            return '$_krEtfPeriod 동안$theme 꾸준히 수익률이 상승한 국내 ETF $n를 찾아주세요. 수익률 추이, AUM, 투자 테마, 주요 편입 종목을 포함하세요.';
          default:
            return '현재 주목받는$theme 국내 테마 ETF $n를 추천해주세요. $_krEtfPeriod 수익률, 운용사, 주요 종목, 투자 포인트를 포함하세요.';
        }
      } else {
        final lev = _krLevType == '전체' ? '' : '$_krLevType ';
        final sec = _krLevSector == '전체' ? '' : '$_krLevSector 관련 ';
        return '한국 국내 상장 $sec${lev}레버리지 ETF $n를 수익률 높은 순으로 알려주세요. 티커, 운용사, 최근 1개월 수익률, AUM, 추종 지수, 특징과 리스크를 포함하세요.';
      }
    } else {
      if (_tabIndex == 1) {
        final theme = _usEtfKeyword.isEmpty ? '' : " '$_usEtfKeyword' 관련";
        switch (_usEtfType) {
          case '지수 추종 ETF':
            return '미국 지수 추종$theme ETF $n를 추천해주세요. $_usEtfPeriod 수익률, AUM, 추종 지수, 특징을 포함하세요.';
          case '테마 ETF':
            return '현재 주목받는$theme 미국 테마 ETF $n를 추천해주세요. $_usEtfPeriod 수익률, 운용사, 주요 종목, 투자 포인트를 포함하세요.';
          case '배당 ETF':
            return '미국 배당$theme ETF $n를 추천해주세요. 배당수익률, 배당 주기, $_usEtfPeriod 수익률, 운용사, 특징을 포함하세요.';
          default:
            return '미국 채권$theme ETF $n를 추천해주세요. 금리 민감도, $_usEtfPeriod 수익률, AUM, 특징과 리스크를 포함하세요.';
        }
      } else {
        final sec = _usLevSector == '전체' ? '' : '$_usLevSector 관련 ';
        return '미국 $sec$_usLevType ETF $n를 $_usSort 기준으로 알려주세요. 티커, 운용사, 최근 1개월 수익률, AUM, 추종 지수, 특징과 리스크를 포함하세요.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          // ── Banner ──────────────────────────────────────────────────────
          _AppBanner(
            subtitle: t['subtitle']!,
            lang: _lang,
            isDark: isDark,
            onLangToggle: () =>
                setState(() => _lang = _lang == 'ko' ? 'en' : 'ko'),
          ),

          // ── Scrollable content ──────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Country tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _countryIndex,
                    thumbColor: isDark ? Colors.white : _kNavy,
                    backgroundColor: isDark
                        ? const Color(0xFF1B1D27)
                        : const Color(0xFFE8EAF0),
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          t['country_kr']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _countryIndex == 0
                                ? (isDark ? _kNavy : Colors.white)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          t['country_us']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _countryIndex == 1
                                ? (isDark ? _kNavy : Colors.white)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (v) {
                      setState(() {
                        _countryIndex = v!;
                        _error = null;
                      });
                      _switchContext();
                    },
                  ),
                ),

                // ── Gap between country & stock-type tabs ────────────────
                const SizedBox(height: 20),

                // Stock-type tab pills
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [0, 1, 2].map((i) {
                      final labels = [
                        t['tab_stocks']!,
                        t['tab_etf']!,
                        t['tab_lev']!,
                      ];
                      final selected = _tabIndex == i;
                      final unselectedBg = isDark
                          ? const Color(0xFF1B1D27)
                          : Colors.white;
                      final unselectedBorder = isDark
                          ? const Color(0xFF2C2F3E)
                          : const Color(0xFFDDE0E8);
                      final unselectedText = isDark
                          ? Colors.white54
                          : Colors.black54;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _tabIndex = i;
                            _error = null;
                          });
                          _switchContext();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 0),
                          decoration: BoxDecoration(
                            color: selected ? _kNavy : unselectedBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? _kNavy : unselectedBorder,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _kNavy.withAlpha(60),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : unselectedText,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilters(isDark),
                ),

                // Search button — 로딩 중엔 중단 버튼, 결과 후 검색 버튼
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: (_loading && _items.isEmpty)
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _cancelSearch,
                              icon: const Icon(Icons.stop_circle_outlined,
                                  size: 18, color: Color(0xFF8A8FA8)),
                              label: Text(
                                _lang == 'ko' ? '중단' : 'Cancel',
                                style: const TextStyle(
                                    color: Color(0xFF8A8FA8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFDDE0E8)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_kNavy, _kNavyMid],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _kNavy.withAlpha(80),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: FilledButton(
                                onPressed: _loading ? null : _search,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.search,
                                        color: _kCyan, size: 18),
                                    const SizedBox(width: 6),
                                    Text(t['search']!,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),

                // Results
                Expanded(child: _buildResults()),

                // Results padding bottom
                const SizedBox(height: 4),
              ],
            ),
          ),

          // ── Bottom disclaimer banner ─────────────────────────────────
          _BottomBanner(
            disclaimer: t['disclaimer']!,
            dataSourcePrefix: t['data_source']!,
            lastFetched: _lastFetched,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Filters ──────────────────────────────────────────────────────────────

  Widget _buildFilters(bool isDark) {
    if (_isKr) {
      if (_tabIndex == 0) return _krStocksFilters(isDark);
      if (_tabIndex == 1) return _krEtfFilters(isDark);
      return _krLevFilters(isDark);
    } else {
      if (_tabIndex == 0) return _usStocksFilters(isDark);
      if (_tabIndex == 1) return _usEtfFilters(isDark);
      return _usLevFilters(isDark);
    }
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    final fillColor = isDark ? const Color(0xFF1B1D27) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2F3E) : const Color(0xFFDDE0E8);
    final textColor = isDark ? Colors.white : Colors.black87;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA8))),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          isDense: true,
          dropdownColor: isDark ? const Color(0xFF1B1D27) : Colors.white,
          style: TextStyle(fontSize: 13, color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kNavy),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.toString(),
                      style: TextStyle(fontSize: 13, color: textColor))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _krStocksFilters(bool isDark) {
    final sectors = _lang == 'ko'
        ? ['전체', '반도체/IT', '2차전지', '바이오/헬스케어', '금융', '자동차', '에너지', '소비재']
        : ['All', 'Semiconductor/IT', 'Battery', 'Bio/Healthcare', 'Finance', 'Auto', 'Energy', 'Consumer'];
    return _dropdown(
      label: t['sector']!,
      value: _krSector == 'all' ? sectors[0] : _krSector,
      items: sectors,
      onChanged: (v) => setState(() => _krSector = v == sectors[0] ? 'all' : v!),
      isDark: isDark,
    );
  }

  Widget _krEtfFilters(bool isDark) {
    return Column(children: [
      Row(children: [
        Expanded(child: _dropdown(label: '유형', value: _krEtfType, items: ['신규 상장 ETF', '꾸준히 수익률 상승', '테마별 추천'], onChanged: (v) => setState(() => _krEtfType = v!), isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(child: _dropdown(label: '기간', value: _krEtfPeriod, items: ['최근 1개월', '최근 3개월', '최근 6개월'], onChanged: (v) => setState(() => _krEtfPeriod = v!), isDark: isDark)),
      ]),
      const SizedBox(height: 8),
      _keywordField(hint: '추가 키워드 (선택) — 예: AI, 배당', value: _krEtfKeyword, onChanged: (v) => _krEtfKeyword = v, isDark: isDark),
    ]);
  }

  Widget _krLevFilters(bool isDark) {
    return Row(children: [
      Expanded(child: _dropdown(label: '유형', value: _krLevType, items: ['전체', '2배 레버리지', '인버스', '인버스 2배'], onChanged: (v) => setState(() => _krLevType = v!), isDark: isDark)),
      const SizedBox(width: 8),
      Expanded(child: _dropdown(label: '섹터', value: _krLevSector, items: ['전체', '코스피200', '코스닥150', '나스닥', '반도체', '2차전지'], onChanged: (v) => setState(() => _krLevSector = v!), isDark: isDark)),
    ]);
  }

  Widget _usStocksFilters(bool isDark) {
    final sectors = _lang == 'ko'
        ? ['전체', '기술/AI', '반도체', '바이오/헬스케어', '금융', '에너지', '소비재', '전기차']
        : ['All', 'Tech/AI', 'Semiconductor', 'Bio/Healthcare', 'Finance', 'Energy', 'Consumer', 'EV'];
    return _dropdown(
      label: t['sector']!,
      value: _usSector == 'all' ? sectors[0] : _usSector,
      items: sectors,
      onChanged: (v) => setState(() => _usSector = v == sectors[0] ? 'all' : v!),
      isDark: isDark,
    );
  }

  Widget _usEtfFilters(bool isDark) {
    return Column(children: [
      Row(children: [
        Expanded(child: _dropdown(label: '유형', value: _usEtfType, items: ['지수 추종 ETF', '테마 ETF', '배당 ETF', '채권 ETF'], onChanged: (v) => setState(() => _usEtfType = v!), isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(child: _dropdown(label: '기간', value: _usEtfPeriod, items: ['최근 1개월', '최근 3개월', '최근 6개월'], onChanged: (v) => setState(() => _usEtfPeriod = v!), isDark: isDark)),
      ]),
      const SizedBox(height: 8),
      _keywordField(hint: 'Keyword — e.g. AI, clean energy', value: _usEtfKeyword, onChanged: (v) => _usEtfKeyword = v, isDark: isDark),
    ]);
  }

  Widget _usLevFilters(bool isDark) {
    return Column(children: [
      Row(children: [
        Expanded(child: _dropdown(label: '배율', value: _usLevType, items: ['2x · 3x 전체', '2배 레버리지', '3배 레버리지', '인버스 레버리지'], onChanged: (v) => setState(() => _usLevType = v!), isDark: isDark)),
        const SizedBox(width: 8),
        Expanded(child: _dropdown(label: '섹터', value: _usLevSector, items: ['전체', '기술/AI', '반도체', '에너지', '금융', '바이오'], onChanged: (v) => setState(() => _usLevSector = v!), isDark: isDark)),
      ]),
      const SizedBox(height: 8),
      _dropdown(label: '정렬', value: _usSort, items: ['수익률 높은 순', 'AUM 큰 순', '거래량 많은 순'], onChanged: (v) => setState(() => _usSort = v!), isDark: isDark),
    ]);
  }

  Widget _keywordField({
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    final fillColor = isDark ? const Color(0xFF1B1D27) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2F3E) : const Color(0xFFDDE0E8);
    return TextFormField(
      initialValue: value,
      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFADB3C8)),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kNavy)),
      ),
      onChanged: onChanged,
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kNavy, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              _lang == 'ko'
                  ? 'AI가 최신 웹 정보를 확인 중입니다.\n첫 조회는 10초 이상 걸릴 수 있어요.'
                  : 'AI is searching the web for latest data.\nFirst load may take 10+ seconds.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA8), height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_error!,
            style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            textAlign: TextAlign.center),
      ));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                _searchedEmpty
                    ? Icons.search_off_rounded
                    : Icons.bar_chart_rounded,
                size: 48,
                color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(_searchedEmpty ? t['no_results']! : t['empty_hint']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFFADB3C8), height: 1.5)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _search,
      color: _kNavy,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: _items.length + (_refreshing ? 1 : 0),
        separatorBuilder: (_, i) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 12, height: 12,
                      child: CircularProgressIndicator(color: _kCyan, strokeWidth: 1.5)),
                  SizedBox(width: 8),
                  Text('최신 데이터로 업데이트 중...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A8FA8))),
                ],
              ),
            );
          }
          return StockCard(item: _items[i], isKorean: _isKr, lang: _lang);
        },
      ),
    );
  }
}

// ── App Banner ────────────────────────────────────────────────────────────────

class _AppBanner extends StatelessWidget {
  final String subtitle;
  final String lang;
  final bool isDark;
  final VoidCallback onLangToggle;

  const _AppBanner({
    required this.subtitle,
    required this.lang,
    required this.isDark,
    required this.onLangToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Light: dark navy gradient bg, white title, cyan subtitle
    // Dark:  white bg, navy title, muted cyan subtitle
    final bgColors = isDark
        ? [Colors.white, const Color(0xFFF5F6FA)]
        : [_kNavy, _kNavyMid];
    final titleColor = isDark ? _kNavy : Colors.white;
    final subtitleColor = isDark ? _kCyanMuted : _kCyan;
    final iconBorder = isDark ? _kNavy.withAlpha(40) : _kCyan.withAlpha(80);
    final iconBg = isDark ? _kNavy.withAlpha(12) : Colors.white.withAlpha(18);
    final toggleBg = isDark ? _kNavy.withAlpha(12) : Colors.white.withAlpha(18);
    final toggleBorder = isDark ? _kNavy.withAlpha(60) : Colors.white.withAlpha(80);
    final toggleText = isDark ? _kNavy : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
          child: Row(
            children: [
              // Chart icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: iconBorder, width: 1),
                ),
                child: CustomPaint(
                  painter: _ChartIconPainter(isDark: isDark),
                ),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stockpulse Select',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        fontFamilyFallback: const [], // SF만 사용 (Noto KR fallback 제거)
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Language toggle
              GestureDetector(
                onTap: onLangToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: toggleBorder, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    color: toggleBg,
                  ),
                  child: Text(
                    lang == 'ko' ? 'English' : '한국어',
                    style: TextStyle(
                      color: toggleText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chart icon painter ────────────────────────────────────────────────────────

class _ChartIconPainter extends CustomPainter {
  final bool isDark;
  const _ChartIconPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = isDark ? _kNavy : _kCyan;
    final glowColor = isDark ? _kNavy.withAlpha(60) : _kCyanDim;
    final w = size.width;
    final h = size.height;

    // Points mimicking the zigzag stock chart in the icon
    final pts = [
      Offset(w * 0.08, h * 0.72),
      Offset(w * 0.28, h * 0.52),
      Offset(w * 0.42, h * 0.70),
      Offset(w * 0.58, h * 0.28),
      Offset(w * 0.74, h * 0.42),
      Offset(w * 0.92, h * 0.22),
    ];

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }

    // Glow layer
    canvas.drawPath(
      path,
      Paint()
        ..color = glowColor
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main line
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dot at the tip
    canvas.drawCircle(pts.last, 3.0, Paint()..color = lineColor);
    canvas.drawCircle(
      pts.last,
      5.5,
      Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Bottom disclaimer banner ──────────────────────────────────────────────────

class _BottomBanner extends StatelessWidget {
  final String disclaimer;
  final String dataSourcePrefix;
  final DateTime? lastFetched;
  final bool isDark;

  const _BottomBanner({
    required this.disclaimer,
    required this.dataSourcePrefix,
    required this.lastFetched,
    required this.isDark,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bgColors = isDark
        ? [const Color(0xFFF5F6FA), Colors.white]
        : [_kNavyMid, _kNavy];
    final textColor = isDark ? _kCyanMuted : _kCyan;
    final dimColor = textColor.withAlpha(160);

    // Second line: source + fetch time (only shown after first search)
    final sourceLine = lastFetched != null
        ? '$dataSourcePrefix${_formatTime(lastFetched!)}'
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            disclaimer,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.center,
          ),
          if (sourceLine != null) ...[
            const SizedBox(height: 3),
            Text(
              sourceLine,
              style: TextStyle(
                color: dimColor,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}


