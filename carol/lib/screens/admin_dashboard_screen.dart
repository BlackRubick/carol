import 'package:carol/models/app_user.dart';
import 'package:carol/services/auth_service.dart';
import 'package:carol/theme/carol_palette.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _confirmDeleteDoctor(
    BuildContext context, {
    required String doctorId,
    required String doctorName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar médico'),
          content: Text(
            '¿Seguro que deseas eliminar a $doctorName?\n\nEsta acción quitará su acceso.',
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

    if (result != true || !context.mounted) return;
    try {
      await AuthService.deleteDoctor(doctorId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Médico eliminado correctamente')),
      );
    } on MockAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = CarolPalette.of(context);

    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
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
            child: StreamBuilder<List<AppUser>>(
              stream: AuthService.streamDoctors(),
              builder: (context, snapshot) {
                final doctors = snapshot.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: palette.redGlow,
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.red, width: 1),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings_outlined,
                            color: palette.red,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panel Admin',
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              'Gestión de médicos',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: AuthService.signOut,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: palette.border),
                            ),
                            child: Icon(
                              Icons.logout_rounded,
                              color: palette.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.border),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.verified_user_outlined,
                          color: palette.textSecondary,
                        ),
                        title: Text(
                          'Administrador',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          AuthService.currentUser?.email ?? '',
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateDoctorDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.red,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text(
                          'Crear médico',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Doctores registrados (${doctors.length})',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (doctors.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Text(
                          'No hay médicos registrados todavía.',
                          style: TextStyle(color: palette.textSecondary),
                        ),
                      )
                    else
                      ...doctors.map(
                        (doctor) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: palette.border),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: palette.surfaceAlt,
                                shape: BoxShape.circle,
                                border: Border.all(color: palette.border),
                              ),
                              child: Icon(
                                Icons.medical_services_outlined,
                                color: palette.red,
                                size: 17,
                              ),
                            ),
                            title: Text(
                              doctor.displayName,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              doctor.email,
                              style: TextStyle(color: palette.textSecondary),
                            ),
                            trailing: IconButton(
                              tooltip: 'Eliminar médico',
                              icon: Icon(
                                Icons.delete_outline,
                                color: palette.red,
                              ),
                              onPressed: () {
                                _confirmDeleteDoctor(
                                  context,
                                  doctorId: doctor.id,
                                  doctorName: doctor.displayName,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDoctorDialog(BuildContext parentContext) async {
    final messenger = ScaffoldMessenger.of(parentContext);

    await showGeneralDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      barrierLabel: 'Cerrar',
      pageBuilder: (dialogContext, _, __) {
        return _CreateDoctorDialogContent(
          onSaved: (name, email, password) async {
            try {
              await AuthService.createDoctor(
                displayName: name,
                email: email,
                password: password,
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Médico creado correctamente')),
                );
              }
            } on MockAuthException catch (e) {
              messenger.showSnackBar(SnackBar(content: Text(e.message)));
              rethrow;
            }
          },
        );
      },
    );
  }
}

class _CreateDoctorDialogContent extends StatefulWidget {
  final Future<void> Function(String name, String email, String password)
  onSaved;

  const _CreateDoctorDialogContent({required this.onSaved});

  @override
  State<_CreateDoctorDialogContent> createState() =>
      _CreateDoctorDialogContentState();
}

class _CreateDoctorDialogContentState
    extends State<_CreateDoctorDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'doctor123');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo médico'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Ingresa nombre válido'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contraseña inicial',
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _saving = true);
                  try {
                    await widget.onSaved(
                      _nameCtrl.text.trim(),
                      _emailCtrl.text.trim(),
                      _passCtrl.text,
                    );
                  } catch (_) {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }
}
