import 'dart:math';

import 'package:carol/models/heart_rate_sample.dart';

enum RiskLevel { low, medium, high }

class RiskAnalysis {
  const RiskAnalysis({
    required this.level,
    required this.score,
    required this.messages,
  });

  final RiskLevel level;
  final int score;
  final List<String> messages;

  String get title => switch (level) {
    RiskLevel.low => 'Riesgo bajo',
    RiskLevel.medium => 'Riesgo moderado',
    RiskLevel.high => 'Riesgo alto',
  };
}

class RiskAnalyzer {
  static RiskAnalysis analyze(List<HeartRateSample> samples) {
    if (samples.isEmpty) {
      return const RiskAnalysis(
        level: RiskLevel.low,
        score: 0,
        messages: ['Sin datos aún para evaluar riesgo.'],
      );
    }

    final sorted = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final latest = sorted.last;
    final last5 = sorted.takeLast(5);
    final last10 = sorted.takeLast(10);

    final avg5 = _avg(last5.map((e) => e.bpm).toList());
    final avg10 = _avg(last10.map((e) => e.bpm).toList());
    final std10 = _stdDev(last10.map((e) => e.bpm).toList());

    final trendWindow = sorted.takeLast(min(6, sorted.length));
    final trend = trendWindow.last.bpm - trendWindow.first.bpm;

    var score = 0;
    final alerts = <String>[];

    if (latest.bpm >= 140) {
      score += 50;
      alerts.add(
        'Pico crítico: frecuencia cardíaca actual muy alta (${latest.bpm} bpm).',
      );
    }

    if (latest.bpm <= 40) {
      score += 50;
      alerts.add('Bradicardia severa detectada (${latest.bpm} bpm).');
    }

    final consecutiveTachy = _consecutiveFromEnd(sorted, (s) => s.bpm >= 120);
    if (consecutiveTachy >= 4) {
      score += 35;
      alerts.add('Taquicardia sostenida en las últimas mediciones.');
    }

    if (avg5 >= 125 && trend >= 8) {
      score += 30;
      alerts.add('Tendencia ascendente con promedio elevado de bpm.');
    }

    if (sorted.length > 1) {
      final prev = sorted[sorted.length - 2];
      if ((latest.bpm - prev.bpm).abs() >= 35) {
        score += 25;
        alerts.add('Cambio súbito de ritmo cardíaco en poco tiempo.');
      }
    }

    if (std10 >= 20 && avg10 >= 100) {
      score += 20;
      alerts.add('Alta variabilidad del ritmo con promedio elevado.');
    }

    if (avg5 >= 110) {
      score += 10;
      alerts.add(
        'Promedio reciente por encima del rango recomendado en reposo.',
      );
    }

    final level = score >= 70
        ? RiskLevel.high
        : score >= 30
        ? RiskLevel.medium
        : RiskLevel.low;

    if (alerts.isEmpty) {
      alerts.add('Sin patrones críticos detectados en este momento.');
    }

    return RiskAnalysis(level: level, score: score, messages: alerts);
  }

  static int _consecutiveFromEnd(
    List<HeartRateSample> samples,
    bool Function(HeartRateSample) condition,
  ) {
    var count = 0;
    for (var i = samples.length - 1; i >= 0; i--) {
      if (!condition(samples[i])) {
        break;
      }
      count++;
    }
    return count;
  }

  static double _avg(List<int> values) {
    if (values.isEmpty) return 0;
    final sum = values.fold<int>(0, (acc, item) => acc + item);
    return sum / values.length;
  }

  static double _stdDev(List<int> values) {
    if (values.length < 2) return 0;
    final mean = _avg(values);
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
    return sqrt(variance);
  }
}

extension _TakeLastExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (isEmpty || count <= 0) return <T>[];
    if (count >= length) return List<T>.from(this);
    return sublist(length - count);
  }
}
