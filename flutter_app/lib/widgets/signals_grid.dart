// lib/widgets/signals_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SignalsGrid extends StatelessWidget {
  final Map<String, dynamic> features;

  const SignalsGrid({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final signals = _signals();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MARKET SIGNALS',
                style: GoogleFonts.ibmPlexMono(
                    color: AppColors.textSecondary,
                    fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: signals.length,
              itemBuilder: (_, i) => _SignalChip(
                label: signals[i].$1,
                value: signals[i].$2,
                color: signals[i].$3,
              ).animate().fadeIn(delay: Duration(milliseconds: 80 * i), duration: 300.ms),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.06, end: 0);
  }

  List<(String, String, Color)> _signals() {
    Color _c(String? val, List<String> pos, List<String> neg) {
      if (val == null) return AppColors.textMuted;
      final v = val.toLowerCase();
      if (pos.any(v.contains)) return AppColors.bullish;
      if (neg.any(v.contains)) return AppColors.bearish;
      return AppColors.sideways;
    }

    final rp = features['rupee_pressure'];

    return [
      ('GLOBAL', _val('global_sentiment'), _c(_val('global_sentiment'), ['positive'], ['negative'])),
      ('GIFT NIFTY', _val('gift_nifty_trend'), _c(_val('gift_nifty_trend'), ['bullish'], ['bearish'])),
      ('BANKING', _val('bank_strength'),    _c(_val('bank_strength'),    ['strong'],   ['weak'])),
      ('NIFTY',   _val('nifty_strength'),   _c(_val('nifty_strength'),   ['strong'],   ['weak'])),
      ('IT/NASDAQ', _val('it_strength'),    _c(_val('it_strength'),      ['strong'],   ['weak'])),
      ('VOLATILITY', _val('volatility'),    _c(_val('volatility'),       ['low'],      ['high'])),
      ('NEWS', _val('news_sentiment'),      _c(_val('news_sentiment'),   ['positive'], ['negative'])),
      ('RUPEE', rp == true ? 'PRESSURE' : 'STABLE',
          rp == true ? AppColors.bearish : AppColors.bullish),
    ];
  }

  String _val(String key) => (features[key] ?? '-').toString().toUpperCase();
}

class _SignalChip extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _SignalChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.ibmPlexMono(color: AppColors.textSecondary, fontSize: 9)),
          Text(value,
              style: GoogleFonts.ibmPlexMono(
                  color: color, fontSize: 9, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
