import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _biometricsEnabledKey = 'biometrics_enabled';

  // Private constructor
  SettingsService._();

  // Single instance
  static final SettingsService _instance = SettingsService._();

  // Factory constructor returns the same instance
  factory SettingsService() => _instance;

  /// Get whether biometric authentication is enabled
  Future<bool> getBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsEnabledKey) ?? false;
  }

  /// Set whether biometric authentication is enabled
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, enabled);
  }
}
