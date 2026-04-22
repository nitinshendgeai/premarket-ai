// lib/widgets/reason_headlines_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ReasonHeadlinesCard extends StatelessWidget {
  final String       reason;
  final List<String> headlines;

  const ReasonHeadlinesCard({
    super.key,
    required this.reason,
    required this.headlines,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Reasoning ──────────────────────────────────────────────
            _label('AI REASONING'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accent.withOpacity(0.18)),
              ),
              child: Text(
                reason,
                style: GoogleFonts.ibmPlexMono(
                    color: AppColors.textPrimary, fontSize: 11, height: 1.7),
              ),
            ),

            // ── Headlines ───────────────────────────────────────────────
            if (headlines.isNotEmpty) ...[
              const SizedBox(height: 20),
              _label('LIVE HEADLINES'),
              const SizedBox(height: 12),
              ...headlines.asMap().entries.map(
                (e) => _Headline(text: e.value, index: e.key),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.ibmPlexMono(
          color: AppColors.textSecondary,
          fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600));
}

class _Headline extends StatelessWidget {
  final String text;
  final int    index;

  const _Headline({required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 10),
            child: Container(
              width: 4, height: 4,
              decoration: const BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
            ),
          ),
          Expanded(
            child: Text(text,
                style: GoogleFonts.ibmPlexMono(
                    color: AppColors.textSecondary, fontSize: 11, height: 1.55)),
          ),
        ],
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: 550 + 60 * index), duration: 300.ms);
  }
}
