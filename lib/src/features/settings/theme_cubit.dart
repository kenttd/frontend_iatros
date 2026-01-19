import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<FThemeData> {
  static const _themeKey = 'theme';

  ThemeCubit() : super(FThemes.yellow.dark) {
    _loadTheme(); // Load saved theme at startup
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? 'yellow_dark';

    if (themeName == 'yellow_light') {
      emit(FThemes.yellow.light);
    } else {
      emit(FThemes.yellow.dark);
    }
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTheme = prefs.getString(_themeKey) ?? 'yellow_dark';

    if (currentTheme == 'yellow_dark') {
      await prefs.setString(_themeKey, 'yellow_light');
      emit(FThemes.yellow.light);
    } else {
      await prefs.setString(_themeKey, 'yellow_dark');
      emit(FThemes.yellow.dark);
    }
  }

  /// Optional: Expose current theme name (handy for switches)
  Future<String> getCurrentThemeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'yellow_dark';
  }
}
