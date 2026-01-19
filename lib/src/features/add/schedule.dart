import 'package:iatros/src/features/add/models/frequency_type.dart';

class Schedule {
  final FrequencyType frequencyType;
  final List<String>? days; // Optional: only for SPECIFIC_DAYS
  final List<String> times; // Array of times like ['08:00', '20:00']

  Schedule({
    required this.frequencyType,
    this.days,
    required this.times,
  });

  Map<String, dynamic> toJson() {
    return {
      'frequencyType': frequencyType.toBackendString(),
      if (days != null && days!.isNotEmpty) 'days': days,
      'times': times,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      frequencyType: FrequencyTypeExtension.fromString(json['frequencyType']),
      days: json['days'] != null ? List<String>.from(json['days']) : null,
      times: List<String>.from(json['times']),
    );
  }

  // Helper to create a display string
  String getDisplayText() {
    final timesStr = times.join(', ');
    switch (frequencyType) {
      case FrequencyType.DAILY:
        return 'Daily at $timesStr';
      case FrequencyType.SPECIFIC_DAYS:
        return '${days?.join(', ')} at $timesStr';
      case FrequencyType.AS_NEEDED:
        return 'As needed';
    }
  }
}