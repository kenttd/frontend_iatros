import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:iatros/src/features/settings/theme_cubit.dart';
import 'package:iatros/src/features/settings/localization_cubit.dart';
import 'package:iatros/src/utils/auth_service.dart';
import 'package:iatros/src/utils/settings_service.dart';
import 'package:iatros/l10n/arb/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricsSettings();
  }

  Future<void> _loadBiometricsSettings() async {
    final enabled = await _settingsService.getBiometricsEnabled();
    setState(() {
      _biometricsEnabled = enabled;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    await _settingsService.setBiometricsEnabled(value);
    setState(() {
      _biometricsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.settingsTitle,
            style: TextStyle(fontSize: 30),
          ),
          SizedBox(height: 30),
          FTile(
            prefix: Icon(FIcons.user),
            title: Text(AppLocalizations.of(context)!.personalizationTitle),
            suffix: Icon(FIcons.chevronRight),
            onPress: () {},
          ),
          SizedBox(height: 10),
          FTile(
            prefix: Icon(FIcons.user),
            title: Text(AppLocalizations.of(context)!.logoutTitle),
            suffix: Icon(FIcons.logOut),
            onPress: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(
                  AppLocalizations.of(context)!.logoutConfirmationTitle,
                ),
                content: Text(
                  AppLocalizations.of(context)!.logoutConfirmationContent,
                ),
                actions: [
                  Row(
                    children: [
                      FButton(
                        onPress: () => Navigator.of(context).pop(),
                        child: Text(AppLocalizations.of(context)!.cancelButton),
                      ),
                      SizedBox(width: 30),
                      FButton(
                        onPress: () {
                          Navigator.of(context).pop();
                          AuthService().signOut();
                        },
                        child: Text(
                          AppLocalizations.of(context)!.continueButton,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          FTile(
            prefix: const Icon(FIcons.fingerprint),
            title: Text(AppLocalizations.of(context)!.biometricTitle),
            subtitle: Text(AppLocalizations.of(context)!.biometricSubtitle),
            suffix: FSwitch(
              value: _biometricsEnabled,
              onChange: _toggleBiometrics,
            ),
          ),
          SizedBox(height: 10),
          FTile(
            prefix: const Icon(FIcons.moon),
            title: Text(AppLocalizations.of(context)!.themeTitle),
            suffix: FSwitch(
              value: context.watch<ThemeCubit>().state == FThemes.yellow.light,
              onChange: (_) => context.read<ThemeCubit>().toggleTheme(),
            ),
          ),
          SizedBox(height: 10),
          FTile(
            prefix: const Icon(FIcons.languages),
            title: Text(AppLocalizations.of(context)!.languageTitle),
            subtitle: Text(
              context.watch<LocalizationCubit>().state.languageCode == 'en'
                  ? 'English'
                  : 'Bahasa Indonesia',
            ),
            suffix: FSwitch(
              value:
                  context.watch<LocalizationCubit>().state.languageCode == 'id',
              onChange: (_) => context.read<LocalizationCubit>().toggleLocale(),
            ),
          ),
        ],
      ),
    );
  }
}
