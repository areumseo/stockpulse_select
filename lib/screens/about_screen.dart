import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: CustomScrollView(
        slivers: [
          // ── 상단 배너 ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1628), Color(0xFF0F2040)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 28,
                24,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Stockpulse Select',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      fontFamilyFallback: [],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'About this app',
                    style: TextStyle(
                      color: Color(0xFF00D4CC),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── 앱 소개 ──────────────────────────────────────────
                _Section(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFF00D4CC),
                  title: '앱 소개',
                  child: const Text(
                    'Stockpulse Select는 Claude AI가 실시간 웹 검색을 통해 국내·미국 주식, ETF, 레버리지 ETF의 최신 이슈와 투자 포인트를 요약해 제공하는 개인용 주식 정보 대시보드입니다.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF3A3F55)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 주요 기능 ─────────────────────────────────────────
                _Section(
                  icon: Icons.grid_view_rounded,
                  iconColor: const Color(0xFF185FA5),
                  title: '주요 기능',
                  child: Column(
                    children: const [
                      _Feature(icon: Icons.flag_rounded, text: '한국·미국 개별주 시가총액 상위 종목 분석'),
                      _Feature(icon: Icons.bar_chart_rounded, text: 'ETF · 레버리지 ETF 검색 및 요약'),
                      _Feature(icon: Icons.language_rounded, text: '한국어 / 영어 전환'),
                      _Feature(icon: Icons.open_in_new_rounded, text: '네이버 증권 · Yahoo Finance 연동'),
                      _Feature(icon: Icons.copy_rounded, text: '종목 코드 길게 눌러 복사'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 데이터 출처 ───────────────────────────────────────
                _Section(
                  icon: Icons.storage_rounded,
                  iconColor: const Color(0xFF3B6D11),
                  title: '데이터 출처',
                  child: const Text(
                    '종목 리스트와 요약은 Claude AI (Anthropic)의 실시간 웹 검색으로 생성하고, 주가·등락률·시가총액 등 수치는 네이버 증권에서 조회합니다. 실시간 호가가 아닌 지연 시세일 수 있습니다.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF3A3F55)),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 투자 면책 조항 ────────────────────────────────────
                _Section(
                  icon: Icons.warning_rounded,
                  iconColor: Colors.red,
                  title: '투자 면책 조항',
                  bgColor: const Color(0xFFFFF5F5),
                  borderColor: const Color(0xFFFFCDD2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '본 앱은 투자 참고 목적으로만 제공됩니다.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB71C1C),
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• 본 앱에서 제공하는 모든 정보는 투자 권유, 매수·매도 추천이 아닙니다.\n'
                        '• 투자 결정은 본인의 판단과 책임 하에 이루어져야 합니다.\n'
                        '• 제공된 데이터는 AI가 검색한 공개 정보이며, 정확성·완전성·최신성을 보장하지 않습니다.\n'
                        '• 주식 투자에는 원금 손실의 위험이 있습니다.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.8,
                          color: Color(0xFF5C2B29),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 버전 정보 ─────────────────────────────────────────
                _Section(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.grey,
                  title: '버전 정보',
                  child: const Text(
                    'Stockpulse Select v1.0.0\nPowered by Claude AI (Anthropic)',
                    style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF3A3F55)),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 카드 ──────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final Color bgColor;
  final Color borderColor;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.bgColor = Colors.white,
    this.borderColor = const Color(0xFFE8EAF0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A1628),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── 기능 항목 ──────────────────────────────────────────────────────────────────
class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0A1628)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF3A3F55)),
            ),
          ),
        ],
      ),
    );
  }
}
