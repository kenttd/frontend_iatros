import 'package:iatros/src/features/add/schedule.dart';
import 'package:iatros/src/features/add/models/duration.dart';

class CreateUserMedication {
  final String rxcui;
  final String medicationName;
  final String dosage;
  final String? instructions;
  final Schedule schedule;
  final Duration duration;

  CreateUserMedication({
    required this.rxcui,
    required this.medicationName,
    required this.dosage,
    this.instructions,
    required this.schedule,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'rxcui': rxcui,
      'medicationName': medicationName,
      'dosage': dosage,
      if (instructions != null && instructions!.isNotEmpty) 'instructions': instructions,
      'schedule': schedule.toJson(),
      'duration': duration.toJson(),
    };
  }
}
