# Stockpulse Select

AI 기반 주식 대시보드 iOS 앱. Claude AI가 실시간 웹 검색으로 한국/미국 시장의 최신 종목 정보를 분석해서 보여줍니다.

## 주요 기능

- **한국/미국 시장** 전환 및 섹터별 탭
- **시가총액 상위 20개 종목** 실시간 조회
- **ETF 검색** (국내/해외/레버리지/인버스, 최근 1개월~6개월 필터)
- **Claude AI 스트리밍**: 카드가 완성되는 순서대로 실시간 표시
- **캐시 전략**: 첫 로드 후 즉시 캐시 표시 + 백그라운드 자동 갱신
- **새로고침**: 위에서 당기기(pull-to-refresh) / 아래로 스크롤
- **검색 중단** 버튼
- **종목 링크**: 한국 → 네이버 증권, 미국 → Yahoo Finance

## 기술 스택

- **Frontend**: Flutter (iOS)
- **Backend**: FastAPI (Render 호스팅)
- **AI**: Anthropic Claude (`claude-sonnet-4-5`) + Web Search Tool
- **통신**: HTTP 스트리밍 + 실시간 JSON 파싱 (brace counting)

## 백엔드

[stock-dashboard](https://github.com/areumseo/stock-dashboard) 리포에서 관리.

API 엔드포인트: `https://stock-dashboard-0atp.onrender.com`

## 실행 방법

```bash
flutter pub get
flutter run
```

릴리스 빌드 (기기 설치):

```bash
flutter build ipa --release --export-method development
xcrun devicectl device install app --device <DEVICE_ID> build/ios/ipa/stockpulse_select.ipa
```
