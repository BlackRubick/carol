import 'package:carol/services/patient_service.dart';
import 'package:carol/theme/carol_palette.dart';
import 'package:flutter/material.dart';

class CreatePatientScreen extends StatefulWidget {
  const CreatePatientScreen({super.key});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen>
    with SingleTickerProviderStateMixin {
  CarolPalette get _palette => CarolPalette.of(context);
  Color get _bg => _palette.bg;
  Color get _surface => _palette.surface;
  Color get _surfaceAlt => _palette.surfaceAlt;
  Color get _red => _palette.red;
  Color get _redDim => _palette.redDim;
  Color get _redGlow => _palette.redGlow;
  Color get _textPrimary => _palette.textPrimary;
  Color get _textSecondary => _palette.textSecondary;
  Color get _border => _palette.border;

  final _formKey = GlobalKey<FormState>();

  // Basic
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String? _sex; // 'Masculino' | 'Femenino' | 'Otro'

  // Body
  final _weightCtrl = TextEditingController(); // kg
  final _heightCtrl = TextEditingController(); // cm

  // Clinical
  final _bloodPressureCtrl = TextEditingController(); // e.g. 120/80
  final _medicationsCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _emergencyContactCtrl = TextEditingController();

  // Risk factors (booleans)
  bool _hypertension = false;
  bool _diabetes = false;
  bool _smoking = false;
  bool _highCholesterol = false;
  bool _familyHistory = false;
  bool _sedentary = false;

  bool _isSaving = false;

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
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _bloodPressureCtrl.dispose();
    _medicationsCtrl.dispose();
    _allergiesCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double? get _bmi {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w == null || h == null || h == 0) return null;
    final hm = h / 100;
    return w / (hm * hm);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final result = await PatientService.createPatient(
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        // Pass additional fields as your PatientService supports them:
        // sex: _sex,
        // weightKg: double.tryParse(_weightCtrl.text),
        // heightCm: double.tryParse(_heightCtrl.text),
        // bloodPressure: _bloodPressureCtrl.text.trim(),
        // medications: _medicationsCtrl.text.trim(),
        // allergies: _allergiesCtrl.text.trim(),
        // emergencyContact: _emergencyContactCtrl.text.trim(),
        // riskFactors: {
        //   'hypertension': _hypertension,
        //   'diabetes': _diabetes,
        //   'smoking': _smoking,
        //   'highCholesterol': _highCholesterol,
        //   'familyHistory': _familyHistory,
        //   'sedentary': _sedentary,
        // },
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Paciente creado'),
            content: SelectableText(
              'Comparte estas credenciales al paciente:\n\n'
              'Correo: ${result.patientEmail}\n'
              'Contraseña: ${result.patientPassword}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _showError('No se pudo crear el paciente');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _red, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: TextStyle(color: _textPrimary)),
            ),
          ],
        ),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _red),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // BG glow
          Positioned(
            top: -100,
            left: -60,
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
                // ── Header ──────────────────────────────────────
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo paciente',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            'Registro de evaluación cardíaca',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Form ────────────────────────────────────────
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      children: [
                        // ── Section: Datos básicos ─────────────
                        _SectionHeader(
                          icon: Icons.person_outline,
                          label: 'Datos básicos',
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _nameCtrl,
                          label: 'Nombre completo',
                          icon: Icons.badge_outlined,
                          validator: (v) {
                            if ((v?.trim() ?? '').length < 3) {
                              return 'Ingresa un nombre válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _ageCtrl,
                                label: 'Edad',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  final a = int.tryParse(v?.trim() ?? '');
                                  if (a == null || a <= 0 || a > 120) {
                                    return 'Edad inválida';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SexDropdown(
                                value: _sex,
                                onChanged: (v) => setState(() => _sex = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _weightCtrl,
                                label: 'Peso (kg)',
                                icon: Icons.monitor_weight_outlined,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null; // optional
                                  }
                                  final w = double.tryParse(v.trim());
                                  if (w == null || w <= 0 || w > 300) {
                                    return 'Valor inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _heightCtrl,
                                label: 'Altura (cm)',
                                icon: Icons.height_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return null;
                                  }
                                  final h = double.tryParse(v.trim());
                                  if (h == null || h < 50 || h > 250) {
                                    return 'Valor inválido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        // IMC preview
                        if (_bmi != null) ...[
                          const SizedBox(height: 8),
                          _BmiChip(bmi: _bmi!),
                        ],

                        const SizedBox(height: 24),

                        // ── Section: Datos clínicos ────────────
                        _SectionHeader(
                          icon: Icons.local_hospital_outlined,
                          label: 'Datos clínicos',
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _bloodPressureCtrl,
                          label: 'Presión arterial base (ej. 120/80)',
                          icon: Icons.speed_outlined,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _medicationsCtrl,
                          label: 'Medicamentos actuales',
                          icon: Icons.medication_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _allergiesCtrl,
                          label: 'Alergias conocidas',
                          icon: Icons.warning_amber_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),

                        _buildField(
                          controller: _emergencyContactCtrl,
                          label: 'Contacto de emergencia (teléfono)',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 24),

                        // ── Section: Factores de riesgo ────────
                        _SectionHeader(
                          icon: Icons.favorite_border,
                          label: 'Factores de riesgo cardíaco',
                        ),
                        const SizedBox(height: 12),

                        _RiskFactorsGrid(
                          hypertension: _hypertension,
                          diabetes: _diabetes,
                          smoking: _smoking,
                          highCholesterol: _highCholesterol,
                          familyHistory: _familyHistory,
                          sedentary: _sedentary,
                          onChanged: (field, value) {
                            setState(() {
                              switch (field) {
                                case 'hypertension':
                                  _hypertension = value;
                                case 'diabetes':
                                  _diabetes = value;
                                case 'smoking':
                                  _smoking = value;
                                case 'highCholesterol':
                                  _highCholesterol = value;
                                case 'familyHistory':
                                  _familyHistory = value;
                                case 'sedentary':
                                  _sedentary = value;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 28),

                        // ── Save button ────────────────────────
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              disabledBackgroundColor: _redDim,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_add_outlined,
                                    size: 20,
                                  ),
                            label: Text(
                              _isSaving ? 'Guardando…' : 'Registrar paciente',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: _textSecondary,
                              size: 13,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Los campos opcionales pueden completarse después. Los factores de riesgo ayudan al análisis de probabilidad de infarto.',
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: _textPrimary, fontSize: 14),
      cursorColor: _red,
      onChanged: (_) => setState(() {}), // for BMI live update
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: _textSecondary, size: 20),
        filled: true,
        fillColor: _surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _red, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _red, width: 1.5),
        ),
        errorStyle: TextStyle(color: _red, fontSize: 11.5),
      ),
      validator: validator,
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  static const _red = Color(0xFFE53E3E);
  static const _textPrimary = Color(0xFFF7FAFC);
  static const _border = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _red, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: _border)),
      ],
    );
  }
}

// ── Sex Dropdown ──────────────────────────────────────────────────────
class _SexDropdown extends StatelessWidget {
  const _SexDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  static const _surfaceAlt = Color(0xFF1C2333);
  static const _red = Color(0xFFE53E3E);
  static const _textPrimary = Color(0xFFF7FAFC);
  static const _textSecondary = Color(0xFF8A98B4);
  static const _border = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1C2333),
      style: TextStyle(color: _textPrimary, fontSize: 14),
      icon: Icon(Icons.expand_more, color: _textSecondary, size: 20),
      decoration: InputDecoration(
        labelText: 'Sexo',
        labelStyle: TextStyle(color: _textSecondary, fontSize: 13),
        prefixIcon: const Icon(
          Icons.wc_outlined,
          color: _textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor: _surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _red, width: 1.5),
        ),
      ),
      items: [
        'Masculino',
        'Femenino',
        'Otro',
      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }
}

// ── BMI Chip ──────────────────────────────────────────────────────────
class _BmiChip extends StatelessWidget {
  const _BmiChip({required this.bmi});
  final double bmi;

  static const _surfaceAlt = Color(0xFF1C2333);

  (Color, String) get _category {
    if (bmi < 18.5) return (const Color(0xFF3182CE), 'Bajo peso');
    if (bmi < 25.0) return (const Color(0xFF38A169), 'Normal');
    if (bmi < 30.0) return (const Color(0xFFDD6B20), 'Sobrepeso');
    return (const Color(0xFFE53E3E), 'Obesidad');
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _category;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calculate_outlined, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                'IMC: ${bmi.toStringAsFixed(1)} · $label',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Risk Factors Grid ─────────────────────────────────────────────────
class _RiskFactorsGrid extends StatelessWidget {
  const _RiskFactorsGrid({
    required this.hypertension,
    required this.diabetes,
    required this.smoking,
    required this.highCholesterol,
    required this.familyHistory,
    required this.sedentary,
    required this.onChanged,
  });

  final bool hypertension;
  final bool diabetes;
  final bool smoking;
  final bool highCholesterol;
  final bool familyHistory;
  final bool sedentary;
  final void Function(String field, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final factors = [
      ('hypertension', hypertension, Icons.bloodtype_outlined, 'Hipertensión'),
      ('diabetes', diabetes, Icons.water_drop_outlined, 'Diabetes'),
      ('smoking', smoking, Icons.smoking_rooms_outlined, 'Tabaquismo'),
      (
        'highCholesterol',
        highCholesterol,
        Icons.science_outlined,
        'Colesterol alto',
      ),
      (
        'familyHistory',
        familyHistory,
        Icons.family_restroom_outlined,
        'Antec. familiares',
      ),
      (
        'sedentary',
        sedentary,
        Icons.airline_seat_recline_extra_outlined,
        'Sedentarismo',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: factors
          .map(
            (f) => _RiskToggle(
              field: f.$1,
              active: f.$2,
              icon: f.$3,
              label: f.$4,
              onChanged: onChanged,
            ),
          )
          .toList(),
    );
  }
}

class _RiskToggle extends StatelessWidget {
  const _RiskToggle({
    required this.field,
    required this.active,
    required this.icon,
    required this.label,
    required this.onChanged,
  });

  final String field;
  final bool active;
  final IconData icon;
  final String label;
  final void Function(String, bool) onChanged;

  static const _surfaceAlt = Color(0xFF1C2333);
  static const _red = Color(0xFFE53E3E);
  static const _redGlow = Color(0x22E53E3E);
  static const _textPrimary = Color(0xFFF7FAFC);
  static const _textSecondary = Color(0xFF8A98B4);
  static const _border = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(field, !active),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _redGlow : _surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? _red.withValues(alpha: 0.6) : _border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? _red : _textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? _textPrimary : _textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
