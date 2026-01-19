import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:iatros/l10n/arb/app_localizations.dart';
import 'package:iatros/src/common_widgets/bottom_navbar.dart';
import 'package:iatros/src/features/add/presentation/add_screen.dart';
import 'package:iatros/src/features/home/presentation/home_screen.dart';
import 'package:iatros/src/features/login/bloc/login_bloc.dart';
import 'package:iatros/src/features/login/presentation/biometric_lock_screen.dart';
import 'package:iatros/src/features/login/presentation/login_screen.dart';
import 'package:iatros/src/features/splash/splash_screen.dart';
import 'package:iatros/src/features/search/bloc/search_bloc.dart';
import 'package:iatros/src/features/search/presentation/search_screen.dart';
import 'package:iatros/src/features/settings/presentation/settings_screen.dart';
import 'package:iatros/src/features/home/bloc/home_bloc.dart';
import 'package:iatros/src/features/settings/theme_cubit.dart';
import 'package:iatros/src/features/settings/localization_cubit.dart';
import 'package:iatros/src/features/messaging/presentation/conversations_screen.dart';
import 'package:iatros/src/features/messaging/presentation/message_thread_screen.dart';
import 'package:iatros/src/utils/api_client.dart';
import 'package:iatros/src/utils/auth_service.dart';
import 'package:iatros/src/utils/settings_service.dart';
import 'package:iatros/src/utils/notification_service.dart';
import 'package:iatros/src/features/map/map_screen.dart';
import 'firebase_options.dart';

// Session tracking for biometric authentication
bool _biometricAuthenticatedThisSession = false;

/// Mark biometric authentication as complete for this session
void setBiometricAuthenticated() {
  _biometricAuthenticatedThisSession = true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized to avoid duplicate app errors on hot reload
  // if (Firebase.apps.isEmpty) {
  //
  // }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();

  // Reset biometric session flag when auth state changes (logout)
  AuthService().firebaseAuth.authStateChanges().listen((user) {
    if (user == null) {
      _biometricAuthenticatedThisSession = false;
    }
  });

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = GoRouter(
    initialLocation: "/splash",
    refreshListenable: AuthService(),
    redirect: (context, state) async {
      final isLoggedIn = AuthService().currentUser != null;
      final isLoggingIn = state.matchedLocation == "/login";
      final isBiometricLock = state.matchedLocation == "/biometric-lock";

      // Allow splash screen to show without redirect
      final isSplash = state.matchedLocation == "/splash";
      if (isSplash) return null;

      // If not logged in, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return "/login";
      }

      // If logged in and on login screen, check biometric settings
      if (isLoggedIn && isLoggingIn) {
        final biometricsEnabled = await SettingsService()
            .getBiometricsEnabled();
        if (biometricsEnabled && !_biometricAuthenticatedThisSession) {
          return "/biometric-lock";
        }
        return "/home";
      }

      // If logged in but not biometrically authenticated yet, redirect to biometric lock
      if (isLoggedIn && !isBiometricLock) {
        final biometricsEnabled = await SettingsService()
            .getBiometricsEnabled();
        if (biometricsEnabled && !_biometricAuthenticatedThisSession) {
          return "/biometric-lock";
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, __) => BlocProvider(
          create: (_) => LoginBloc(AuthService()),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/biometric-lock',
        builder: (_, _) => const BiometricLockScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return FScaffold(
            footer: const BottomNavbar(),
            child: SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          );
        },
        routes: [
          GoRoute(
            path: "/home",
            pageBuilder: (context, state) =>
                NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: "/settings",
            pageBuilder: (context, state) =>
                NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: "/search",
            pageBuilder: (context, state) {
              return NoTransitionPage(child: SearchScreen());
            },
          ),
          GoRoute(
            path: "/add",
            pageBuilder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              return NoTransitionPage(child: AddScreen(data: data));
            },
          ),
          GoRoute(
            path: "/map",
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MapScreen()),
          ),
          GoRoute(
            path: "/messaging",
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ConversationsScreen()),
          ),
          GoRoute(
            path: "/messaging/:id",
            pageBuilder: (context, state) {
              final conversationId = state.pathParameters['id'] ?? '';
              final extra = state.extra as Map<String, dynamic>?;
              final participantName = extra?['participantName'] as String?;
              return NoTransitionPage(
                child: MessageThreadScreen(
                  conversationId: conversationId,
                  participantName: participantName,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => SearchBloc()),
        BlocProvider(
          create: (_) => HomeBloc(ApiClient(), NotificationService()),
        ),
        BlocProvider(create: (_) => LocalizationCubit()),
      ],
      child: BlocBuilder<ThemeCubit, FThemeData>(
        builder: (context, theme) {
          return BlocBuilder<LocalizationCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp.router(
                routerConfig: _router,
                builder: (context, child) => FTheme(data: theme, child: child!),
                title: "iatros",
                debugShowCheckedModeBanner: false,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              );
            },
          );
        },
      ),
    );
  }
}
