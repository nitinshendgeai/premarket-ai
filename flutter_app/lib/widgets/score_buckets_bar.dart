// lib/widgets/score_buckets_bar.dart
// Shows the weighted scoring breakdown as a horizontal stacked bar.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ScoreBucketsBar extends StatelessWidget {
  final Map<String, dynamic> scoreBuckets;

  const ScoreBucketsBar({super.key, required this.scoreBuckets});

  @override
  Widget build(BuildContext context) {
    final bull = (scoreBuckets['bullish'] as num? ?? 0).toDouble();
    final bear = (scoreBuckets['bearish'] as num? ?? 0).toDouble();
    final side = (scoreBuckets['sideways'] as num? ?? 0).toDouble();
    final total = bull + bear + side;
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SIGNAL SCORE BREAKDOWN',
                style: GoogleFonts.ibmPlexMono(
                    color: AppColors.textSecondary,
                    fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (_, t, __) => Row(children: [
                  if (bull > 0)
                    Expanded(
                      flex: (bull * t).round(),
                      child: Container(height: 10, color: AppColors.bullish),
                    ),
                  if (side > 0)
                    Expanded(
                      flex: (side * t).round(),
                      child: Container(height: 10, color: AppColors.sideways),
                    ),
                  if (bear > 0)
                    Expanded(
                      flex: (bear * t).round(),
                      child: Container(height: 10, color: AppColors.bearish),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _leg('BULL', bull.toInt(), AppColors.bullish),
                _leg('SIDE', side.toInt(), AppColors.sideways),
                _leg('BEAR', bear.toInt(), AppColors.bearish),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }

  Widget _leg(String label, int pts, Color color) {
    return Row(children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 6),
      Text('$label  $pts pts',
          style: GoogleFonts.ibmPlexMono(color: AppColors.textSecondary, fontSize: 9)),
    ]);
  }
}
