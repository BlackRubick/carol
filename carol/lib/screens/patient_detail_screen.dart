import 'dart:async';
import 'dart:math';

import 'package:carol/models/heart_rate_sample.dart';
import 'package:carol/models/patient.dart';
import 'package:carol/services/patient_service.dart';
import '../services/heart_rate_api_service.dart';
import 'package:carol/services/risk_analyzer.dart';
import 'package:carol/theme/carol_palette.dart';
import 'package:flutter/material.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key, required this.patient});

  final Patient patient;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  CarolPalette get _palette => CarolPalette.of(context);
  Color get _bg => _palette.bg;
  Color get _surface => _palette.surface;
  Color get _red => _palette.red;
  Color get _redGlow => _palette.redGlow;
  Color get _textPrimary => _palette.textPrimary;
  Color get _textSecondary => _palette.textSecondary;
  Color get _border => _palette.border;

  String? _lastAlertKey;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }



  void _showRealtimeAlertIfNeeded(RiskAnalysis analysis) {
    if (analysis.level != RiskLevel.high) return;
    final key =
        '${analysis.level.name}-${analysis.score}-${analysis.messages.first}';
    if (_lastAlertKey == key) return;
    _lastAlertKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emergency, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '⚠️ Alerta: ${analysis.messages.first}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x12E53E3E), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _textSecondary,
                          size: 18,
                        ),
                      ),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _redGlow,
                            shape: BoxShape.circle,
                            border: Border.all(color: _red, width: 1),
                          ),
                          child: Icon(
                            Icons.monitor_heart_outlined,
                            color: _red,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patient.name,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${widget.patient.age} años • Monitoreo cardíaco',
                              style: TextStyle(
                                fontSize: 11,
                                color: _textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Body ──────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<HeartRateSample>>(
                    stream: Stream.periodic(const Duration(seconds: 1), (_) => null)
                        .asyncMap((_) => HeartRateApiService.fetchHeartRates()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: _red),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: \\${snapshot.error}'));
                      }
                      final samples = snapshot.data ?? [];
                      final analysis = RiskAnalyzer.analyze(samples);
                      _showRealtimeAlertIfNeeded(analysis);

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: [
                          _RiskCard(analysis: analysis),
                          const SizedBox(height: 12),
                          _RealtimeChartCard(
                            samples: samples,
                            liveMode: true,
                            onToggleLive: (_) {}, // Desactivado, solo visual
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: _textSecondary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Registros recientes',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (samples.isEmpty)
                            _emptyRecords()
                          else
                            ...samples.take(20).map((s) => _HeartRateRow(sample: s)),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: _textSecondary,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Aviso: Este análisis es orientativo y no sustituye diagnóstico médico profesional.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRecords() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Text(
          'Sin registros de ritmo cardíaco todavía.',
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
      ),
    );
  }
}

// ── Risk Card ────────────────────────────────────────────────────────
class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.analysis});
  final RiskAnalysis analysis;

  static const _surface = Color(0xFF111827);
  static const _border = Color(0xFF2D3748);
  static const _textPrimary = Color(0xFFF7FAFC);
  static const _textSecondary = Color(0xFF8A98B4);

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon) = switch (analysis.level) {
      RiskLevel.low => (
        const Color(0xFF38A169),
        const Color(0xFF1A2E22),
        Icons.check_circle_outline,
      ),
      RiskLevel.medium => (
        const Color(0xFFDD6B20),
        const Color(0xFF2D1F0E),
        Icons.warning_amber_rounded,
      ),
      RiskLevel.high => (
        const Color(0xFFE53E3E),
        const Color(0xFF2D1010),
        Icons.emergency_rounded,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  analysis.title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  'Score ${analysis.score}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (analysis.messages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 1, color: _border),
            const SizedBox(height: 10),
            ...analysis.messages.map(
              (msg) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: color, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        msg,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Chart Card ───────────────────────────────────────────────────────
class _RealtimeChartCard extends StatelessWidget {
  const _RealtimeChartCard({
    required this.samples,
    required this.liveMode,
    required this.onToggleLive,
  });

  final List<HeartRateSample> samples;
  final bool liveMode;
  final ValueChanged<bool> onToggleLive;

  static const _surface = Color(0xFF111827);
  static const _red = Color(0xFFE53E3E);
  static const _green = Color(0xFF38A169);
  static const _textPrimary = Color(0xFFF7FAFC);
  static const _textSecondary = Color(0xFF8A98B4);
  static const _border = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    final latestBpm = samples.isEmpty ? null : samples.first.bpm;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: _red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ritmo cardíaco en tiempo real',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Live toggle pill
              GestureDetector(
                onTap: () => onToggleLive(!liveMode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: liveMode
                        ? const Color(0xFF1A2E22)
                        : const Color(0xFF1C2333),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: liveMode ? _green.withOpacity(0.5) : _border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: liveMode ? _green : _textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        liveMode ? 'EN VIVO' : 'PAUSADO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: liveMode ? _green : _textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (latestBpm != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$latestBpm',
                  style: TextStyle(
                    color: _red,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Georgia',
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'bpm',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: _AnimatedHeartRateChart(samples: samples),
          ),
        ],
      ),
    );
  }
}

// ── Heart Rate Row ───────────────────────────────────────────────────
class _HeartRateRow extends StatelessWidget {
  const _HeartRateRow({required this.sample});
  final HeartRateSample sample;

  static const _surface = Color(0xFF111827);
  static const _surfaceAlt = Color(0xFF1C2333);
  static const _red = Color(0xFFE53E3E);
  static const _textSecondary = Color(0xFF8A98B4);
  static const _border = Color(0xFF2D3748);

  Color _bpmColor(int bpm) {
    if (bpm < 60 || bpm > 100) return _red;
    if (bpm < 65 || bpm > 90) return const Color(0xFFDD6B20);
    return const Color(0xFF38A169);
  }

  @override
  Widget build(BuildContext context) {
    final color = _bpmColor(sample.bpm);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Icon(Icons.favorite, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sample.timestamp.toLocal().toString().substring(0, 19),
              style: TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ),
          Text(
            '${sample.bpm}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'bpm',
            style: TextStyle(color: _textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Animated Chart ───────────────────────────────────────────────────
class _AnimatedHeartRateChart extends StatelessWidget {
  const _AnimatedHeartRateChart({required this.samples});
  final List<HeartRateSample> samples;

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) {
      return Center(
        child: Text(
          'Sin datos para graficar',
          style: TextStyle(color: Color(0xFF8A98B4), fontSize: 13),
        ),
      );
    }

    final ordered = samples.reversed.take(30).toList();

    return TweenAnimationBuilder<double>(
      key: ValueKey('${samples.first.id}-${samples.length}'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return CustomPaint(
          painter: _HeartRateChartPainter(points: ordered, progress: progress),
        );
      },
    );
  }
}

class _HeartRateChartPainter extends CustomPainter {
  _HeartRateChartPainter({required this.points, required this.progress});

  final List<HeartRateSample> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 8.0;
    const bottomPad = 12.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;

    final values = points.map((e) => e.bpm.toDouble()).toList();
    final minBpm = values.reduce(min) - 8;
    final maxBpm = values.reduce(max) + 8;
    final span = (maxBpm - minBpm).clamp(20, 220).toDouble();

    // Dark grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF2D3748)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = (chartH / 3) * i;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFE53E3E)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE53E3E).withOpacity(0.22),
          const Color(0xFFE53E3E).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    Offset pointAt(int i) {
      final x = leftPad + (chartW * (i / (points.length - 1).clamp(1, 9999)));
      final normalized = (points[i].bpm - minBpm) / span;
      final y = chartH - (normalized * chartH);
      return Offset(x, y);
    }

    final maxIndex = max(1, (points.length * progress).ceil());
    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);

    // Smooth curve using cubic bezier
    for (var i = 1; i < maxIndex; i++) {
      final prev = pointAt(i - 1);
      final curr = pointAt(i);
      final cpX = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(pointAt(maxIndex - 1).dx, chartH)
      ..lineTo(pointAt(0).dx, chartH)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Live dot
    final current = pointAt(maxIndex - 1);
    canvas.drawCircle(current, 10, Paint()..color = const Color(0x22E53E3E));
    canvas.drawCircle(current, 5, Paint()..color = const Color(0xFFE53E3E));
    canvas.drawCircle(current, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _HeartRateChartPainter old) =>
      old.points != points || old.progress != progress;
}
