import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:iatros/src/features/login/bloc/login_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:iatros/src/features/login/presentation/login.dart';
import 'package:iatros/src/features/login/presentation/register.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iatros/l10n/arb/app_localizations.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginBloc = context.read<LoginBloc>();
    return FScaffold(
      resizeToAvoidBottomInset:
          true, // 👈 important so Scaffold pushes content up
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(
                  context,
                ).viewInsets.bottom, // 👈 ensures padding when keyboard shows
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 200),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Lottie.asset(
                          'lib/src/assets/login_animation2.json',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FTabs(
                        children: [
                          FTabEntry(
                            label: Text(
                              AppLocalizations.of(context)!.loginTitle,
                            ),
                            child: const LoginPage(),
                          ),
                          FTabEntry(
                            label: Text(
                              AppLocalizations.of(context)!.registerTitle,
                            ),
                            child: RegisterPage(loginBloc: loginBloc),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
