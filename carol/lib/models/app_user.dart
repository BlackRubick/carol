enum UserRole { admin, doctor, patient }

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.linkedPatientId,
  });

  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final String? linkedPatientId;

  bool get isAdmin => role == UserRole.admin;
  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;
}
