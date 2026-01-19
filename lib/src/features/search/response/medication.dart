class Medication {
  final String name;
  final String rxcui;

  Medication({
    required this.name,
    required this.rxcui,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      rxcui: json['rxcui'],
    );
  }
}