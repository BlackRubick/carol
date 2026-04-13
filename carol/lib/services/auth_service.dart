import 'dart:async';

import 'package:carol/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._();

  static const adminEmail = 'admin@carol.com';
  static const adminPassword = 'admin123';
  static const allowedEmail = 'doctor@hotmail.com';
  static const allowedPassword = 'doctor123';
  static const defaultPatientPassword = 'paciente123';

  static final List<_StoredAccount> _accounts = [
    _StoredAccount(
      user: const AppUser(
        id: 'admin-1',
        email: adminEmail,
        displayName: 'Administrador General',
        role: UserRole.admin,
      ),
      password: adminPassword,
    ),
    _StoredAccount(
      user: const AppUser(
        id: 'doctor-1',
        email: allowedEmail,
        displayName: 'Dr. Principal',
        role: UserRole.doctor,
      ),
      password: allowedPassword,
    ),
    _StoredAccount(
      user: const AppUser(
        id: 'patient-user-1',
        email: 'paciente1@carol.com',
        displayName: 'Juan Pérez',
        role: UserRole.patient,
        linkedPatientId: 'p1',
      ),
      password: defaultPatientPassword,
    ),
    _StoredAccount(
      user: const AppUser(
        id: 'patient-user-2',
        email: 'paciente2@carol.com',
        displayName: 'María López',
        role: UserRole.patient,
        linkedPatientId: 'p2',
      ),
      password: defaultPatientPassword,
    ),
    _StoredAccount(
      user: const AppUser(
        id: 'patient-user-3',
        email: 'paciente3@carol.com',
        displayName: 'Carlos Ramírez',
        role: UserRole.patient,
        linkedPatientId: 'p3',
      ),
      password: defaultPatientPassword,
    ),
    _StoredAccount(
      user: const AppUser(
        id: 'patient-user-4',
        email: 'paciente4@carol.com',
        displayName: 'Ana Hernández',
        role: UserRole.patient,
        linkedPatientId: 'p4',
      ),
      password: defaultPatientPassword,
    ),
    _StoredAccount(
      user: const AppUser(
        id: 'patient-user-5',
        email: 'paciente5@carol.com',
        displayName: 'Luis Gómez',
        role: UserRole.patient,
        linkedPatientId: 'p5',
      ),
      password: defaultPatientPassword,
    ),
  ];

  static final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast()..add(null);

  static final StreamController<List<AppUser>> _doctorsController =
      StreamController<List<AppUser>>.broadcast();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static bool _seededFirestore = false;

  static AppUser? _currentUser;

  static CollectionReference<Map<String, dynamic>> get _accountsRef =>
      _db.collection('auth_accounts');

  static Stream<AppUser?> authStateChanges() => _authController.stream;

  static bool get isSignedIn => _currentUser != null;
  static AppUser? get currentUser => _currentUser;

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _ensureSeededInFirestore();

    final normalizedEmail = email.trim().toLowerCase();
    _StoredAccount? account;
    for (final entry in _accounts) {
      if (entry.user.email.toLowerCase() == normalizedEmail) {
        account = entry;
        break;
      }
    }

    if (account == null) {
      account = await _loadAccountByEmail(normalizedEmail);
      if (account != null &&
          !_accounts.any(
            (a) => a.user.email.toLowerCase() == normalizedEmail,
          )) {
        _accounts.add(account);
      }
    }

    if (account == null || account.password != password) {
      throw const MockAuthException(
        'Credenciales inválidas. Revisa correo y contraseña.',
      );
    }

    _currentUser = account.user;
    _authController.add(_currentUser);
  }

  static Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  static Stream<List<AppUser>> streamDoctors() async* {
    await _ensureSeededInFirestore();
    yield _doctorUsers();

    yield* _accountsRef
        .where('role', isEqualTo: UserRole.doctor.name)
        .snapshots()
        .map((snapshot) {
          final doctors =
              snapshot.docs
                  .map((doc) => _storedAccountFromMap(doc.id, doc.data()).user)
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName));
          return doctors;
        });
  }

  static Future<void> createDoctor({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await _ensureSeededInFirestore();

    if (_currentUser?.role != UserRole.admin) {
      throw const MockAuthException('Solo el admin puede crear doctores.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final exists =
        _accounts.any((a) => a.user.email.toLowerCase() == normalizedEmail) ||
        await _emailExistsInFirestore(normalizedEmail);
    if (exists) {
      throw const MockAuthException('Ese correo ya está registrado.');
    }

    final doctor = AppUser(
      id: 'doctor-${DateTime.now().microsecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: displayName.trim(),
      role: UserRole.doctor,
    );

    _accounts.add(_StoredAccount(user: doctor, password: password));
    await _accountsRef.doc(doctor.id).set({
      'email': doctor.email,
      'displayName': doctor.displayName,
      'role': doctor.role.name,
      'linkedPatientId': doctor.linkedPatientId,
      'password': password,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    _emitDoctors();
  }

  static Future<void> deleteDoctor(String doctorId) async {
    await _ensureSeededInFirestore();

    if (_currentUser?.role != UserRole.admin) {
      throw const MockAuthException('Solo el admin puede eliminar doctores.');
    }

    final doc = await _accountsRef.doc(doctorId).get();
    if (!doc.exists) {
      throw const MockAuthException('El doctor ya no existe.');
    }

    final data = doc.data() ?? <String, dynamic>{};
    if ((data['role'] as String?) != UserRole.doctor.name) {
      throw const MockAuthException('La cuenta indicada no es de médico.');
    }

    await _accountsRef.doc(doctorId).delete();
    _accounts.removeWhere((a) => a.user.id == doctorId);
    _emitDoctors();
  }

  static Future<PatientUserCredentials> registerPatientAccount({
    required String patientId,
    required String patientName,
  }) async {
    await _ensureSeededInFirestore();

    final base = patientName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'\.+'), '.')
        .replaceAll(RegExp(r'^\.|\.$'), '');

    final root = base.isEmpty ? 'paciente' : base;
    var email = '$root@carol.com';
    var index = 1;
    while (_accounts.any((a) => a.user.email.toLowerCase() == email) ||
        await _emailExistsInFirestore(email)) {
      email = '$root.$index@carol.com';
      index++;
    }

    final password = defaultPatientPassword;
    final user = AppUser(
      id: 'patient-user-${DateTime.now().microsecondsSinceEpoch}',
      email: email,
      displayName: patientName,
      role: UserRole.patient,
      linkedPatientId: patientId,
    );

    _accounts.add(_StoredAccount(user: user, password: password));
    await _accountsRef.doc(user.id).set({
      'email': user.email,
      'displayName': user.displayName,
      'role': user.role.name,
      'linkedPatientId': user.linkedPatientId,
      'password': password,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
    return PatientUserCredentials(email: email, password: password);
  }

  static Future<void> deleteAccountByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    _accounts.removeWhere((a) => a.user.email.toLowerCase() == normalized);

    final snapshot = await _accountsRef
        .where('email', isEqualTo: normalized)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  static List<AppUser> _doctorUsers() {
    return _accounts
        .map((a) => a.user)
        .where((u) => u.role == UserRole.doctor)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  static void _emitDoctors() {
    _doctorsController.add(_doctorUsers());
  }

  static Future<void> _ensureSeededInFirestore() async {
    if (_seededFirestore) return;

    for (final account in _accounts) {
      await _accountsRef.doc(account.user.id).set({
        'email': account.user.email,
        'displayName': account.user.displayName,
        'role': account.user.role.name,
        'linkedPatientId': account.user.linkedPatientId,
        'password': account.password,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    }

    _seededFirestore = true;
  }

  static Future<bool> _emailExistsInFirestore(String email) async {
    final result = await _accountsRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  static Future<_StoredAccount?> _loadAccountByEmail(String email) async {
    final result = await _accountsRef
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (result.docs.isEmpty) return null;
    final doc = result.docs.first;
    return _storedAccountFromMap(doc.id, doc.data());
  }

  static _StoredAccount _storedAccountFromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final roleName = (data['role'] as String?) ?? UserRole.patient.name;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => UserRole.patient,
    );

    final user = AppUser(
      id: id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? 'Usuario',
      role: role,
      linkedPatientId: data['linkedPatientId'] as String?,
    );

    return _StoredAccount(
      user: user,
      password: (data['password'] as String?) ?? '',
    );
  }
}

class PatientUserCredentials {
  const PatientUserCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class _StoredAccount {
  const _StoredAccount({required this.user, required this.password});

  final AppUser user;
  final String password;
}

class MockAuthException implements Exception {
  const MockAuthException(this.message);

  final String message;
}
