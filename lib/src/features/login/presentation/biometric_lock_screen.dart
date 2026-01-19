import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:iatros/src/utils/auth_service.dart';
import 'package:iatros/main.dart' show setBiometricAuthenticated;

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _statusMessage = 'Authenticating...';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      // Check if device supports biometrics
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          _statusMessage = 'Biometric authentication not available on this device';
          _isAuthenticating = false;
        });
        return;
      }

      // Attempt biometric authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access iatros',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        // Authentication successful, mark session and navigate to home
        setBiometricAuthenticated();
        if (mounted) {
          context.go('/home');
        }
      } else {
        // Authentication failed
        setState(() {
          _statusMessage = 'Authentication failed. Please try again.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isAuthenticating = false;
      });
    }
  }

  void _logout() async {
    await AuthService().signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FIcons.lock,
                  size: 80,
                ),
                const SizedBox(height: 30),
                const Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                if (!_isAuthenticating)
                  FButton(
                    onPress: _authenticate,
                    prefix: const Icon(FIcons.fingerprint),
                    child: const Text('Try Again'),
                  ),
                const SizedBox(height: 16),
                FButton(
                  onPress: _logout,
                  style: FButtonStyle.outline(),
                  prefix: const Icon(FIcons.logOut),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
