// lib/models/analysis_model.dart
// Dart models matching the FastAPI /premarket-analysis response schema.

class StrikeInfo {
  final String strikeLabel;
  final int?   strikeValue;
  final int    step;
  final String note;

  const StrikeInfo({
    required this.strikeLabel,
    this.strikeValue,
    required this.step,
    required this.note,
  });

  factory StrikeInfo.fromJson(Map<String, dynamic> j) => StrikeInfo(
    strikeLabel: j['strike_label'] ?? 'ATM',
    strikeValue: j['strike_value'],
    step:        (j['step'] ?? 100) as int,
    note:        j['note'] ?? '',
  );
}

class RiskInfo {
  final int?   stopLossPct;
  final int?   targetPct;
  final String note;
  final String? advice;
  final String timeExit;

  const RiskInfo({
    this.stopLossPct,
    this.targetPct,
    required this.note,
    this.advice,
    required this.timeExit,
  });

  factory RiskInfo.fromJson(Map<String, dynamic> j) => RiskInfo(
    stopLossPct: j['stop_loss_pct'],
    targetPct:   j['target_pct'],
    note:        j['note'] ?? '',
    advice:      j['advice'],
    timeExit:    j['time_exit'] ?? 'N/A',
  );
}

class MarketTick {
  final double? close;
  final double? pctChange;
  final String? trend;

  const MarketTick({this.close, this.pctChange, this.trend});

  factory MarketTick.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const MarketTick();
    return MarketTick(
      close:     (j['close'] as num?)?.toDouble(),
      pctChange: (j['pct_change'] as num?)?.toDouble(),
      trend:     j['trend'],
    );
  }

  bool get hasData => close != null;
  bool get isBullish => trend == 'bullish';
}

class AnalysisResult {
  final String   bias;
  final int      confidence;
  final String   index;
  final String   strategy;
  final StrikeInfo strike;
  final RiskInfo   risk;
  final String   reason;
  final List<String> topHeadlines;
  final Map<String, dynamic> features;
  final Map<String, dynamic> scoreBuckets;
  final Map<String, MarketTick> rawMarket;

  const AnalysisResult({
    required this.bias,
    required this.confidence,
    required this.index,
    required this.strategy,
    required this.strike,
    required this.risk,
    required this.reason,
    required this.topHeadlines,
    required this.features,
    required this.scoreBuckets,
    required this.rawMarket,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    final rawMap = (j['raw_market'] as Map<String, dynamic>?) ?? {};
    return AnalysisResult(
      bias:          j['bias']       ?? 'sideways',
      confidence:    j['confidence'] ?? 0,
      index:         j['index']      ?? 'NIFTY 50',
      strategy:      j['strategy']   ?? 'Avoid',
      strike:        StrikeInfo.fromJson(j['strike'] ?? {}),
      risk:          RiskInfo.fromJson(j['risk']     ?? {}),
      reason:        j['reason']     ?? '',
      topHeadlines:  List<String>.from(j['top_headlines'] ?? []),
      features:      Map<String, dynamic>.from(j['features']      ?? {}),
      scoreBuckets:  Map<String, dynamic>.from(j['score_buckets'] ?? {}),
      rawMarket: {
        'nifty':      MarketTick.fromJson(rawMap['nifty']),
        'bank_nifty': MarketTick.fromJson(rawMap['bank_nifty']),
        'india_vix':  MarketTick.fromJson(rawMap['india_vix']),
        'sp500':      MarketTick.fromJson(rawMap['sp500']),
        'nasdaq':     MarketTick.fromJson(rawMap['nasdaq']),
      },
    );
  }

  bool get isBullish  => bias == 'bullish';
  bool get isBearish  => bias == 'bearish';
  bool get isSideways => bias == 'sideways';
  bool get shouldTrade => strategy != 'Avoid';
}
