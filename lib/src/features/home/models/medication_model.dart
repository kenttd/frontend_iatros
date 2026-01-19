class MedicationSchedule {
  final String? dayOfWeek; // null for daily/as_needed, specific day for specific_days
  final String time;

  MedicationSchedule({
    this.dayOfWeek,
    required this.time,
  });

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) {
    return MedicationSchedule(
      dayOfWeek: json['dayOfWeek'] as String?,
      time: json['time'] as String,
    );
  }
}

class MedicationInventory {
  final int currentQuantity;
  final int? initialQuantity;

  MedicationInventory({
    required this.currentQuantity,
    this.initialQuantity,
  });

  factory MedicationInventory.fromJson(Map<String, dynamic> json) {
    return MedicationInventory(
      currentQuantity: json['currentQuantity'] as int,
      initialQuantity: json['initialQuantity'] as int?,
    );
  }
}

class PrescribedByDoctor {
  final String id;
  final String fullName;

  PrescribedByDoctor({
    required this.id,
    required this.fullName,
  });

  factory PrescribedByDoctor.fromJson(Map<String, dynamic> json) {
    return PrescribedByDoctor(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
    );
  }
}

class Medication {
  final String id;
  final String rxcui;
  final String medicationName;
  final String dosage;
  final String? instructions;
  final String frequencyType;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MedicationSchedule> schedules;
  final MedicationInventory? inventory;
  final PrescribedByDoctor? prescribedByDoctor;

  Medication({
    required this.id,
    required this.rxcui,
    required this.medicationName,
    required this.dosage,
    this.instructions,
    required this.frequencyType,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.schedules,
    this.inventory,
    this.prescribedByDoctor,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      rxcui: json['rxcui'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      instructions: json['instructions'] as String?,
      frequencyType: json['frequencyType'] as String,
      startDate: _parseTimestamp(json['startDate']),
      endDate: json['endDate'] != null ? _parseTimestamp(json['endDate']) : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      schedules: (json['schedules'] as List?)
              ?.map((e) => MedicationSchedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inventory: json['inventory'] != null
          ? MedicationInventory.fromJson(json['inventory'] as Map<String, dynamic>)
          : null,
      prescribedByDoctor: json['prescribedByDoctor'] != null
          ? PrescribedByDoctor.fromJson(json['prescribedByDoctor'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is Map) {
      // Firestore Timestamp format
      final seconds = timestamp['_seconds'] as int;
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return DateTime.now();
  }

  /// Get the next scheduled time for this medication today or upcoming
  DateTime? getNextScheduledTime() {
    if (schedules.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get today's day name
    final dayName = _getDayName(now.weekday);

    // Find schedules for today
    final todaySchedules = schedules.where((s) {
      // If dayOfWeek is null, it's a daily medication (applies every day)
      if (s.dayOfWeek == null) return true;
      // If dayOfWeek is set, check if it matches today
      return s.dayOfWeek == dayName;
    }).toList();

    if (todaySchedules.isEmpty) return null;

    // Parse times and find next upcoming time
    for (final schedule in todaySchedules) {
      final timeParts = schedule.time.split(':');
      if (timeParts.length != 2) continue;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour == null || minute == null) continue;

      final scheduledTime = DateTime(today.year, today.month, today.day, hour, minute);
      if (scheduledTime.isAfter(now)) {
        return scheduledTime;
      }
    }

    return null;
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}
