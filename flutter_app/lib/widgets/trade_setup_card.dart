// lib/widgets/trade_setup_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/analysis_model.dart';
import '../theme/app_theme.dart';

class TradeSetupCard extends StatelessWidget {
  final String     index;
  final String     strategy;
  final StrikeInfo strike;
  final RiskInfo   risk;

  const TradeSetupCard({
    super.key,
    required this.index,
    required this.strategy,
    required this.strike,
    required this.risk,
  });

  Color get _stratColor {
    if (strategy.contains('CE')) return AppColors.bullish;
    if (strategy.contains('PE')) return AppColors.bearish;
    return AppColors.sideways;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('TRADE SETUP'),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(child: _dataBox('INDEX', index, AppColors.accent)),
              const SizedBox(width: 10),
              Expanded(child: _dataBox('STRATEGY', strategy, _stratColor, highlighted: strategy != 'Avoid')),
            ]),

            const SizedBox(height: 10),
            _dataBox('STRIKE', strike.strikeLabel, AppColors.textPrimary),
            const SizedBox(height: 4),
            Text(strike.note,
                style: GoogleFonts.ibmPlexMono(color: AppColors.textMuted, fontSize: 10, height: 1.5)),

            if (risk.stopLossPct != null) ...[
              const SizedBox(height: 18),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 14),
              _sectionTitle('RISK MANAGEMENT'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _riskPill('STOP LOSS', '${risk.stopLossPct}%', AppColors.bearish)),
                const SizedBox(width: 10),
                Expanded(child: _riskPill('TARGET', '${risk.targetPct}%', AppColors.bullish)),
              ]),
              if (risk.advice != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(risk.advice!,
                      style: GoogleFonts.ibmPlexMono(
                          color: AppColors.textSecondary, fontSize: 10, height: 1.6)),
                ),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.access_time_rounded, color: AppColors.textMuted, size: 12),
                const SizedBox(width: 6),
                Text('Time exit: ${risk.timeExit}',
                    style: GoogleFonts.ibmPlexMono(color: AppColors.textMuted, fontSize: 10)),
              ]),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _sectionTitle(String t) => Text(t,
      style: GoogleFonts.ibmPlexMono(
          color: AppColors.textSecondary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600));

  Widget _dataBox(String label, String value, Color valueColor, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlighted ? valueColor.withOpacity(0.08) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlighted ? valueColor.withOpacity(0.3) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.ibmPlexMono(
                color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.5)),
        const SizedBox(height: 5),
        Text(value,
            style: GoogleFonts.ibmPlexMono(
                color: valueColor, fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _riskPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.ibmPlexMono(color: AppColors.textSecondary, fontSize: 10)),
        Text(value,
            style: GoogleFonts.ibmPlexMono(
                color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
