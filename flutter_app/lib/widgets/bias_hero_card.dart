// lib/widgets/bias_hero_card.dart
// The centrepiece hero card: large bias label + animated confidence meter.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BiasHeroCard extends StatelessWidget {
  final String bias;
  final int    confidence;

  const BiasHeroCard({super.key, required this.bias, required this.confidence});

  String get _label => bias.toUpperCase();

  String get _tagline {
    switch (bias.toLowerCase()) {
      case 'bullish':  return 'Markets trending UP — look for Call opportunities';
      case 'bearish':  return 'Markets trending DOWN — look for Put opportunities';
      default:         return 'No clear direction — consider staying on sidelines';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forBias(bias);
    final bg    = AppColors.bgForBias(bias);
    final icon  = AppColors.iconForBias(bias);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header row ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'MARKET BIAS',
                style: GoogleFonts.ibmPlexMono(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Bias label ─────────────────────────────────────────────────
          Text(
            _label,
            style: GoogleFonts.ibmPlexMono(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              height: 1,
            ),
          )
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 8),

          Text(
            _tagline,
            style: GoogleFonts.ibmPlexMono(
              color: color.withOpacity(0.65),
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // ── Confidence bar ─────────────────────────────────────────────
          _ConfidenceMeter(confidence: confidence, color: color),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms)
    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
  }
}

class _ConfidenceMeter extends StatelessWidget {
  final int   confidence;
  final Color color;

  const _ConfidenceMeter({required this.confidence, required this.color});

  String get _label {
    if (confidence >= 75) return 'HIGH CONVICTION';
    if (confidence >= 50) return 'MODERATE';
    return 'LOW CONVICTION';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CONFIDENCE  ·  $_label',
              style: GoogleFonts.ibmPlexMono(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '$confidence%',
              style: GoogleFonts.ibmPlexMono(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: confidence / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOut,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}
