class Duration {
  final DateTime startDate;
  final DateTime? endDate;

  Duration({
    required this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
      if (endDate != null) 'endDate': endDate!.toIso8601String().split('T')[0],
    };
  }

  factory Duration.fromJson(Map<String, dynamic> json) {
    return Duration(
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }
}
