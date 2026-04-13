import 'package:carol/models/heart_rate_sample.dart';
import 'package:carol/models/patient.dart';
import 'package:carol/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientService {
  PatientService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _db.collection('patients');

  static Stream<List<Patient>> streamPatients() async* {
    yield* _patientsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Patient.fromDoc).toList())
        .map(_visiblePatientsForCurrentUser);
  }

  static Future<PatientRegistrationResult> createPatient({
    required String name,
    required int age,
  }) async {
    final doctor = AuthService.currentUser;
    if (doctor == null || !doctor.isDoctor) {
      throw const MockAuthException('Solo un médico puede crear pacientes.');
    }

    final patientDoc = _patientsRef.doc();
    final patientId = patientDoc.id;
    final credentials = await AuthService.registerPatientAccount(
      patientId: patientId,
      patientName: name.trim(),
    );

    final patient = Patient(
      id: patientId,
      name: name.trim(),
      age: age,
      createdAt: DateTime.now(),
      createdByDoctorId: doctor.id,
      patientUserEmail: credentials.email,
    );
    await patientDoc.set({
      'name': patient.name,
      'age': patient.age,
      'createdAt': Timestamp.fromDate(patient.createdAt),
      'createdByDoctorId': patient.createdByDoctorId,
      'patientUserEmail': patient.patientUserEmail,
    });

    return PatientRegistrationResult(
      patient: patient,
      patientEmail: credentials.email,
      patientPassword: credentials.password,
    );
  }

  static Stream<List<HeartRateSample>> streamHeartRates(
    String patientId,
  ) async* {
    yield* _patientsRef
        .doc(patientId)
        .collection('heart_rates')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(HeartRateSample.fromDoc).toList());
  }

  static Future<void> addHeartRateSample({
    required String patientId,
    required int bpm,
  }) async {
    await _patientsRef.doc(patientId).collection('heart_rates').add({
      'bpm': bpm,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  static Future<void> updatePatient({
    required String patientId,
    required String name,
    required int age,
  }) async {
    final doctor = AuthService.currentUser;
    if (doctor == null || !doctor.isDoctor) {
      throw const MockAuthException('Solo un médico puede editar pacientes.');
    }

    final doc = await _patientsRef.doc(patientId).get();
    if (!doc.exists) {
      throw const MockAuthException('Paciente no encontrado.');
    }

    final patient = Patient.fromDoc(doc);
    if (patient.createdByDoctorId != doctor.id) {
      throw const MockAuthException(
        'No puedes editar pacientes creados por otro médico.',
      );
    }

    await _patientsRef.doc(patientId).update({'name': name.trim(), 'age': age});
  }

  static Future<void> deletePatient(Patient patient) async {
    final doctor = AuthService.currentUser;
    if (doctor == null || !doctor.isDoctor) {
      throw const MockAuthException('Solo un médico puede eliminar pacientes.');
    }

    if (patient.createdByDoctorId != doctor.id) {
      throw const MockAuthException(
        'No puedes eliminar pacientes creados por otro médico.',
      );
    }

    final heartRatesRef = _patientsRef
        .doc(patient.id)
        .collection('heart_rates');
    final heartRates = await heartRatesRef.get();
    final batch = _db.batch();

    for (final doc in heartRates.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_patientsRef.doc(patient.id));
    await batch.commit();

    if (patient.patientUserEmail != null &&
        patient.patientUserEmail!.isNotEmpty) {
      await AuthService.deleteAccountByEmail(patient.patientUserEmail!);
    }
  }

  static List<Patient> _visiblePatientsForCurrentUser(List<Patient> patients) {
    final currentUser = AuthService.currentUser;

    if (currentUser == null) return const [];
    if (currentUser.isAdmin) return patients;
    if (currentUser.isDoctor) {
      return patients
          .where((p) => p.createdByDoctorId == currentUser.id)
          .toList();
    }
    if (currentUser.isPatient && currentUser.linkedPatientId != null) {
      return patients
          .where((p) => p.id == currentUser.linkedPatientId)
          .toList();
    }

    return const [];
  }

  static Future<Patient?> getPatientById(String patientId) async {
    final doc = await _patientsRef.doc(patientId).get();
    if (!doc.exists) return null;
    return Patient.fromDoc(doc);
  }
}

class PatientRegistrationResult {
  const PatientRegistrationResult({
    required this.patient,
    required this.patientEmail,
    required this.patientPassword,
  });

  final Patient patient;
  final String patientEmail;
  final String patientPassword;
}
