class Metric {
  final String label;
  final String value;
  final bool? positive;

  Metric({required this.label, required this.value, this.positive});

  factory Metric.fromJson(Map<String, dynamic> json) => Metric(
        label: json['label'] ?? '',
        value: json['value'] ?? '',
        positive: json['positive'],
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'positive': positive,
      };
}

class StockItem {
  final String name;
  final String code;
  final String summary;
  final List<Metric> metrics;
  final String badge;
  final String badgeType;

  StockItem({
    required this.name,
    required this.code,
    required this.summary,
    required this.metrics,
    required this.badge,
    required this.badgeType,
  });

  /// Claude 웹 검색 citation 태그 제거: <cite index="...">...</cite>
  static String _clean(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll(RegExp(r'<cite[^>]*>'), '')
        .replaceAll('</cite>', '')
        .trim();
  }

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        name: _clean(json['name']),
        code: _clean(json['code']),
        summary: _clean(json['summary']),
        metrics: (json['metrics'] as List? ?? [])
            .map((m) => Metric.fromJson(m))
            .toList(),
        badge: json['badge'] ?? '',
        badgeType: json['badgeType'] ?? 'up',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'summary': summary,
        'metrics': metrics.map((m) => m.toJson()).toList(),
        'badge': badge,
        'badgeType': badgeType,
      };
}
