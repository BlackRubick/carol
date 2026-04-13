import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.createdAt,
    required this.createdByDoctorId,
    this.patientUserEmail,
  });

  final String id;
  final String name;
  final int age;
  final DateTime createdAt;
  final String createdByDoctorId;
  final String? patientUserEmail;

  factory Patient.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawDate = data['createdAt'];

    return Patient(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Sin nombre',
      age: (data['age'] as num?)?.toInt() ?? 0,
      createdAt: rawDate is Timestamp ? rawDate.toDate() : DateTime.now(),
      createdByDoctorId:
          (data['createdByDoctorId'] as String?)?.trim() ?? 'doctor-unknown',
      patientUserEmail: (data['patientUserEmail'] as String?)?.trim(),
    );
  }
}
