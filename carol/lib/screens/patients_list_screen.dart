import 'package:carol/models/patient.dart';
import 'package:carol/screens/create_patient_screen.dart';
import 'package:carol/screens/patient_detail_screen.dart';
import 'package:carol/services/auth_service.dart';
import 'package:carol/services/patient_service.dart';
import 'package:carol/theme/carol_palette.dart';
import 'package:flutter/material.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen>
    with SingleTickerProviderStateMixin {
  CarolPalette get _palette => CarolPalette.of(context);
  Color get _bg => _palette.bg;
  Color get _surfaceAlt => _palette.surfaceAlt;
  Color get _red => _palette.red;
  Color get _redGlow => _palette.redGlow;
  Color get _textPrimary => _palette.textPrimary;
  Color get _textSecondary => _palette.textSecondary;
  Color get _border => _palette.border;

  final _searchCtrl = TextEditingController();
  String _query = '';

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));

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
    _searchCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<Patient> _filter(List<Patient> patients) {
    if (_query.trim().isEmpty) return patients;
    final q = _query.trim().toLowerCase();
    return patients.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Background glow ──────────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _redGlow,
                            shape: BoxShape.circle,
                            border: Border.all(color: _red, width: 1),
                          ),
                            child: Icon(
                            Icons.monitor_heart_outlined,
                            color: _red,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CardioAlert',
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Lista de pacientes',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Logout button
                      Tooltip(
                        message: 'Cerrar sesión',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => AuthService.signOut(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _border),
                            ),
                              child: Icon(
                              Icons.logout_rounded,
                              color: _textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Search bar ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(color: _textPrimary, fontSize: 14),
                    cursorColor: _red,
                    decoration: InputDecoration(
                      hintText: 'Buscar paciente…',
                      hintStyle: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                        prefixIcon: Icon(
                        Icons.search,
                        color: _textSecondary,
                        size: 20,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                                icon: Icon(
                                Icons.close,
                                color: _textSecondary,
                                size: 18,
                              ),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: _surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                  ),
                ),

                const SizedBox(height: 16),

                // ── List ────────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<Patient>>(
                    stream: PatientService.streamPatients(),
                    builder: (context, snapshot) {
                      // Loading
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: _red));
                      }

                      // Error
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(
                                Icons.error_outline,
                                color: _red,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Error cargando pacientes',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final all = snapshot.data ?? [];
                      final patients = _filter(all);

                      // Empty state
                      if (all.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: _surfaceAlt,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _border),
                                ),
                                  child: Icon(
                                  Icons.person_off_outlined,
                                  color: _textSecondary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                                Text(
                                'Sin pacientes aún',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                                Text(
                                'Crea el primer registro.',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // No search results
                      if (patients.isEmpty) {
                        return Center(
                          child: Text(
                            'Sin resultados para "$_query"',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      // Patient list
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          return _PatientCard(
                            patient: patient,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PatientDetailScreen(patient: patient),
                                ),
                              );
                            },
                            onEdit: () => _showEditPatientDialog(patient),
                            onDelete: () => _confirmDeletePatient(patient),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── FAB ───────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePatientScreen()),
          );
        },
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text(
          'Nuevo paciente',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Future<void> _showEditPatientDialog(Patient patient) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: patient.name);
    final ageCtrl = TextEditingController(text: patient.age.toString());

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar paciente'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Nombre inválido'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Edad'),
                      validator: (v) {
                        final age = int.tryParse((v ?? '').trim());
                        if (age == null || age <= 0 || age > 120) {
                          return 'Edad inválida';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => saving = true);
                          try {
                            await PatientService.updatePatient(
                              patientId: patient.id,
                              name: nameCtrl.text.trim(),
                              age: int.parse(ageCtrl.text.trim()),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Paciente actualizado'),
                              ),
                            );
                          } on MockAuthException catch (e) {
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(SnackBar(content: Text(e.message)));
                            setState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    ageCtrl.dispose();
  }

  Future<void> _confirmDeletePatient(Patient patient) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar paciente'),
          content: Text(
            '¿Seguro que deseas eliminar a ${patient.name}?\n\nSe borrarán sus registros e historial.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      await PatientService.deletePatient(patient);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paciente eliminado correctamente')),
      );
    } on MockAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

// ── Patient card widget ──────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Patient patient;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = CarolPalette.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0x1AE53E3E),
        highlightColor: const Color(0x0DE53E3E),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: palette.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${patient.age} años',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.more_horiz, color: palette.red, size: 18),
                ),
                color: palette.surfaceAlt,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                  PopupMenuItem<String>(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
