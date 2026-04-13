
import 'package:carol/models/heart_rate_sample.dart';
import '../services/infarto_prediction_service.dart';
import 'package:carol/services/auth_service.dart';
import 'package:carol/services/patient_service.dart';
import '../services/heart_rate_api_service.dart';
import 'package:carol/theme/carol_palette.dart';
import 'package:flutter/material.dart';
import 'dart:async';


class PatientPortalScreen extends StatefulWidget {
  const PatientPortalScreen({super.key});

  @override
  State<PatientPortalScreen> createState() => _PatientPortalScreenState();
}

class _PatientPortalScreenState extends State<PatientPortalScreen> {
  bool _alertShown = false;
  DateTime? _lastAlertTime;
  late final Duration _checkInterval = const Duration(minutes: 5);
  Stream<List<HeartRateSample>>? _heartRateStream;

  @override
  void initState() {
    super.initState();
    _heartRateStream = Stream.periodic(const Duration(seconds: 1), (_) => null)
        .asyncMap((_) => HeartRateApiService.fetchHeartRates());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPeriodicCheck());
  }

  @override
  void dispose() {
    _periodicCheckActive = false;
    super.dispose();
  }

  bool _periodicCheckActive = true;

  Future<void> _startPeriodicCheck() async {
    while (mounted && _periodicCheckActive) {
      await _checkInfartoPrediction(context);
      await Future.delayed(_checkInterval);
    }
  }

  Future<void> _checkInfartoPrediction(BuildContext context) async {
    try {
      final riesgo = await InfartoPredictionService.fetchInfartoRisk();
      if (riesgo) {
        final now = DateTime.now();
        if (_lastAlertTime == null || now.difference(_lastAlertTime!) > _checkInterval) {
          _lastAlertTime = now;
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¡Alerta de Infarto!'),
                content: const Text('El sistema detecta un posible riesgo de infarto en los próximos 40 minutos. Por favor, consulta a un médico de inmediato.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final palette = CarolPalette.of(context);
    final user = AuthService.currentUser;
    final patientId = user?.linkedPatientId;

    if (user == null || patientId == null) {
      return Scaffold(
        backgroundColor: palette.bg,
        body: Center(
          child: Text(
            'No se encontró perfil de paciente.',
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Historial de ritmo cardíaco',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<HeartRateSample>>(
                stream: _heartRateStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \\${snapshot.error}'));
                  }
                  final samples = snapshot.data ?? const [];
                  if (samples.isEmpty) {
                    return Center(
                      child: Text(
                        'No hay registros todavía.',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return ListView(
                    children: samples.take(30).map((s) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: palette.surfaceAlt,
                                shape: BoxShape.circle,
                                border: Border.all(color: palette.border),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: palette.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.timestamp
                                    .toLocal()
                                    .toString()
                                    .substring(0, 19),
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '${s.bpm}',
                              style: TextStyle(
                                color: palette.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'bpm',
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
