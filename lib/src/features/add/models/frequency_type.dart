enum FrequencyType {
  DAILY,
  SPECIFIC_DAYS,
  AS_NEEDED,
}

extension FrequencyTypeExtension on FrequencyType {
  String toBackendString() {
    switch (this) {
      case FrequencyType.DAILY:
        return 'DAILY';
      case FrequencyType.SPECIFIC_DAYS:
        return 'SPECIFIC_DAYS';
      case FrequencyType.AS_NEEDED:
        return 'AS_NEEDED';
    }
  }

  static FrequencyType fromString(String value) {
    switch (value) {
      case 'DAILY':
        return FrequencyType.DAILY;
      case 'SPECIFIC_DAYS':
        return FrequencyType.SPECIFIC_DAYS;
      case 'AS_NEEDED':
        return FrequencyType.AS_NEEDED;
      default:
        throw ArgumentError('Invalid frequency type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case FrequencyType.DAILY:
        return 'Daily';
      case FrequencyType.SPECIFIC_DAYS:
        return 'Specific Days';
      case FrequencyType.AS_NEEDED:
        return 'As Needed';
    }
  }
}
