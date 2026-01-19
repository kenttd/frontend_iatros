import 'package:iatros/src/features/search/response/medication.dart';

class MedicationResult {
  final int count;
  final List<Medication> results;

  MedicationResult({
    required this.count,
    required this.results,
  });

  factory MedicationResult.fromJson(Map<String, dynamic> json) {
    return MedicationResult(
      count: json['count'],
      results: (json['results'] as List)
          .map((item) => Medication.fromJson(item))
          .toList(),
    );
  }
}