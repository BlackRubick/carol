import 'package:carol/models/app_user.dart';
import 'package:carol/screens/admin_dashboard_screen.dart';
import 'package:carol/screens/login_screen.dart';
import 'package:carol/screens/patient_portal_screen.dart';
import 'package:carol/screens/patients_list_screen.dart';
import 'package:carol/services/auth_service.dart';
import 'package:carol/theme/app_theme.dart';
import 'package:carol/theme/theme_mode_controller.dart';
import 'package:carol/widgets/theme_mode_fab.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CarolApp());
}

class CarolApp extends StatelessWidget {
  const CarolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CarolThemeRoot();
  }
}

class _CarolThemeRoot extends StatefulWidget {
  const _CarolThemeRoot();

  @override
  State<_CarolThemeRoot> createState() => _CarolThemeRootState();
}

class _CarolThemeRootState extends State<_CarolThemeRoot> {
  final ThemeModeController _themeModeController = ThemeModeController();

  @override
  void dispose() {
    _themeModeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Carol - Monitor de Riesgo Cardiaco',
          theme: carolLightTheme,
          darkTheme: carolDarkTheme,
          themeMode: themeMode,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                ThemeModeFab(
                  themeMode: themeMode,
                  onToggle: _themeModeController.toggle,
                ),
              ],
            );
          },
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      initialData: AuthService.currentUser,
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return switch (user.role) {
          UserRole.admin => const AdminDashboardScreen(),
          UserRole.doctor => const PatientsListScreen(),
          UserRole.patient => const PatientPortalScreen(),
        };
      },
    );
  }
}