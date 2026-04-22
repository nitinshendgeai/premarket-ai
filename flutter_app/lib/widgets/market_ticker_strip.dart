// lib/widgets/market_ticker_strip.dart
// Horizontally scrollable strip of index prices.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_model.dart';
import '../theme/app_theme.dart';

class MarketTickerStrip extends StatelessWidget {
  final Map<String, MarketTick> rawMarket;

  const MarketTickerStrip({super.key, required this.rawMarket});

  static const _labels = {
    'nifty':      'NIFTY',
    'bank_nifty': 'BNIFTY',
    'india_vix':  'VIX',
    'sp500':      'S&P 500',
    'nasdaq':     'NASDAQ',
  };

  @override
  Widget build(BuildContext context) {
    final ticks = _labels.entries
        .map((e) => (e.value, rawMarket[e.key]))
        .where((t) => t.$2?.hasData == true)
        .toList();

    if (ticks.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ticks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _TickCard(
          label: ticks[i].$1,
          tick:  ticks[i].$2!,
        ).animate().fadeIn(delay: Duration(milliseconds: 60 * i), duration: 300.ms),
      ),
    );
  }
}

class _TickCard extends StatelessWidget {
  final String    label;
  final MarketTick tick;

  const _TickCard({required this.label, required this.tick});

  Color get _color => tick.isBullish ? AppColors.bullish : AppColors.bearish;

  String get _pctStr {
    final p = tick.pctChange;
    if (p == null) return '';
    final sign = p >= 0 ? '+' : '';
    return '$sign${p.toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.ibmPlexMono(
                  color: AppColors.textMuted, fontSize: 8, letterSpacing: 1.5)),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(tick.close!.toStringAsFixed(2),
                style: GoogleFonts.ibmPlexMono(
                    color: AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text(_pctStr,
                style: GoogleFonts.ibmPlexMono(color: _color, fontSize: 10)),
          ]),
        ],
      ),
    );
  }
}
