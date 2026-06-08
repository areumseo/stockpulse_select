import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/about_screen.dart';

void main() {
  runApp(const StockpulseApp());
}

class StockpulseApp extends StatelessWidget {
  const StockpulseApp({super.key});

  // 영문: San Francisco (iOS 시스템 폰트)
  // 한글: Noto Sans KR (fallback — SF에 한글 글리프 없을 때 자동 적용)
  static TextTheme _textTheme() {
    final notoKr = GoogleFonts.notoSansKr().fontFamily!;

    TextStyle withKr(TextStyle? s) =>
        (s ?? const TextStyle()).copyWith(fontFamilyFallback: [notoKr]);

    final base = ThemeData.light().textTheme;
    return base.copyWith(
      displayLarge:   withKr(base.displayLarge),
      displayMedium:  withKr(base.displayMedium),
      displaySmall:   withKr(base.displaySmall),
      headlineLarge:  withKr(base.headlineLarge),
      headlineMedium: withKr(base.headlineMedium),
      headlineSmall:  withKr(base.headlineSmall),
      titleLarge:     withKr(base.titleLarge),
      titleMedium:    withKr(base.titleMedium),
      titleSmall:     withKr(base.titleSmall),
      bodyLarge:      withKr(base.bodyLarge),
      bodyMedium:     withKr(base.bodyMedium),
      bodySmall:      withKr(base.bodySmall),
      labelLarge:     withKr(base.labelLarge),
      labelMedium:    withKr(base.labelMedium),
      labelSmall:     withKr(base.labelSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockpulse Select',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        cardColor: Colors.white,
        textTheme: _textTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A1628),
          brightness: Brightness.light,
        ),
      ),

      home: const _RootScreen(),
    );
  }
}

class _RootScreen extends StatefulWidget {
  const _RootScreen();

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  int _tab = 0;

  static const _screens = [
    HomeScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: const Color(0xFF0A1628),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: '검색',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline_rounded),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
