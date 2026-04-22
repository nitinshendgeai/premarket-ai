// lib/screens/dashboard_screen.dart
// Main pre-market dashboard screen with full state management.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/analysis_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bias_hero_card.dart';
import '../widgets/trade_setup_card.dart';
import '../widgets/signals_grid.dart';
import '../widgets/score_buckets_bar.dart';
import '../widgets/market_ticker_strip.dart';
import '../widgets/reason_headlines_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AnalysisResult? _result;
  bool            _loading  = false;
  String?         _error;
  DateTime?       _lastFetch;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.fetchPremarketAnalysis();
      setState(() { _result = result; _lastFetch = DateTime.now(); });
    } on ApiException catch (e) {
      setState(() { _error = e.message; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(children: [
            _Header(
              onRefresh:  _fetch,
              loading:    _loading,
              lastFetch:  _lastFetch,
            ),
            Expanded(child: _body()),
          ]),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _result == null) return _LoadingView();
    if (_error  != null && _result == null) {
      return _ErrorView(message: _error!, onRetry: _fetch);
    }
    if (_result == null) return _EmptyView(onRefresh: _fetch);
    return _ResultView(result: _result!, refreshing: _loading);
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool         loading;
  final DateTime?    lastFetch;

  const _Header({required this.onRefresh, required this.loading, this.lastFetch});

  @override
  Widget build(BuildContext context) {
    final timeStr = lastFetch != null
        ? DateFormat('HH:mm:ss').format(lastFetch!)
        : '--:--:--';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        // Logo mark
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: const Icon(Icons.candlestick_chart_rounded,
              color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PRE-MARKET AI',
              style: GoogleFonts.ibmPlexMono(
                  color: AppColors.accent,
                  fontSize: 10, letterSpacing: 2.5, fontWeight: FontWeight.w600)),
          Text('Indian Options Assistant',
              style: GoogleFonts.ibmPlexMono(
                  color: AppColors.textPrimary,
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('LAST UPDATE', style: GoogleFonts.ibmPlexMono(
              color: AppColors.textMuted, fontSize: 8, letterSpacing: 1)),
          Text(timeStr, style: GoogleFonts.ibmPlexMono(
              color: AppColors.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(width: 4),
        IconButton(
          onPressed: loading ? null : onRefresh,
          icon: loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.accent))
              : const Icon(Icons.refresh_rounded,
                  color: AppColors.accent, size: 20),
          tooltip: 'Refresh analysis',
        ),
      ]),
    );
  }
}

// ── Result view ─────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final AnalysisResult result;
  final bool           refreshing;

  const _ResultView({required this.result, required this.refreshing});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [

          // Market ticker strip
          MarketTickerStrip(rawMarket: result.rawMarket),
          const SizedBox(height: 14),

          // Hero bias card
          BiasHeroCard(bias: result.bias, confidence: result.confidence),
          const SizedBox(height: 10),

          // Trade setup
          TradeSetupCard(
            index:    result.index,
            strategy: result.strategy,
            strike:   result.strike,
            risk:     result.risk,
          ),
          const SizedBox(height: 10),

          // Signal grid
          SignalsGrid(features: result.features),
          const SizedBox(height: 10),

          // Score breakdown bar
          ScoreBucketsBar(scoreBuckets: result.scoreBuckets),
          const SizedBox(height: 10),

          // Reasoning + headlines
          ReasonHeadlinesCard(
              reason: result.reason, headlines: result.topHeadlines),
          const SizedBox(height: 10),

          // Disclaimer
          _Disclaimer(),
        ],
      ),

      // Refresh overlay — thin top bar
      if (refreshing)
        Positioned(
          top: 0, left: 0, right: 0,
          child: LinearProgressIndicator(
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 2,
          ),
        ),
    ]);
  }
}

// ── Loading ─────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.accent),
        ),
        const SizedBox(height: 24),
        Text('Fetching live market data…',
            style: GoogleFonts.ibmPlexMono(
                color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Text('NIFTY · BANK NIFTY · VIX · GLOBAL · NEWS',
            style: GoogleFonts.ibmPlexMono(
                color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.5)),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bearish.withOpacity(0.08),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.bearish.withOpacity(0.25)),
            ),
            child: const Icon(Icons.cloud_off_rounded,
                color: AppColors.bearish, size: 40),
          ),
          const SizedBox(height: 20),
          Text('Connection Failed',
              style: GoogleFonts.ibmPlexMono(
                  color: AppColors.textPrimary,
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexMono(
                    color: AppColors.textSecondary,
                    fontSize: 11, height: 1.7)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Retry', style: GoogleFonts.ibmPlexMono()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}

// ── Empty ────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('No data yet',
            style: GoogleFonts.ibmPlexMono(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRefresh,
          child: Text('Load Analysis', style: GoogleFonts.ibmPlexMono()),
        ),
      ]),
    );
  }
}

// ── Disclaimer ────────────────────────────────────────────────────────────────

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sideways.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.sideways.withOpacity(0.12)),
      ),
      child: Text(
        '⚠  FOR EDUCATIONAL USE ONLY.\n'
        'This is not financial advice. Options trading involves substantial risk of loss. '
        'Always do your own research before placing any trade.',
        textAlign: TextAlign.center,
        style: GoogleFonts.ibmPlexMono(
            color: AppColors.textMuted, fontSize: 9, height: 1.7),
      ),
    );
  }
}
