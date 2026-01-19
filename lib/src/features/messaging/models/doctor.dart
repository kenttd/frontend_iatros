class Doctor {
  final String id;
  final String displayName;
  final String? email;
  final String? specialty;
  final String? hospitalClinicName;

  Doctor({
    required this.id,
    required this.displayName,
    this.email,
    this.specialty,
    this.hospitalClinicName,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String?,
      specialty: json['specialty'] as String?,
      hospitalClinicName: json['hospitalClinicName'] as String?,
    );
  }
}
