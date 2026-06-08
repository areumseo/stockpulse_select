# Stockpulse Select

An AI-powered stock dashboard iOS app. Claude AI searches the web in real time to analyze and display the latest stock information for Korean and US markets.

## Features

- **Korean / US market** switching with sector tabs
- **Top 20 stocks by market cap** with real-time data
- **ETF search** (domestic / overseas / leveraged / inverse, with 1M–6M filters)
- **Claude AI streaming**: cards appear one by one as they're ready
- **Cache strategy**: instant cache display on load + background auto-refresh
- **Refresh**: pull-to-refresh from top / scroll to bottom
- **Cancel search** button
- **Stock links**: Korean stocks → Naver Finance, US stocks → Yahoo Finance

## Tech Stack

- **Frontend**: Flutter (iOS)
- **Backend**: FastAPI (hosted on Render)
- **AI**: Anthropic Claude (`claude-sonnet-4-5`) + Web Search Tool
- **Streaming**: HTTP streaming + real-time JSON parsing (brace counting)

## Backend

Managed in the [stock-dashboard](https://github.com/areumseo/stock-dashboard) repository.

API endpoint: `https://stock-dashboard-0atp.onrender.com`

## Getting Started

```bash
flutter pub get
flutter run
```

Release build (device install):

```bash
flutter build ipa --release --export-method development
xcrun devicectl device install app --device <DEVICE_ID> build/ios/ipa/stockpulse_select.ipa
```
