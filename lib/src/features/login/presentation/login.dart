import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:iatros/src/features/login/bloc/login_bloc.dart';
import 'package:iatros/src/features/login/bloc/login_event.dart';
import 'package:iatros/src/features/login/bloc/login_state.dart';
import 'package:iatros/src/utils/auth_service.dart';
import 'package:iatros/l10n/arb/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        } else if (state is LoginFailure) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Login failed: ${state.error}'),
          //     backgroundColor: Colors.red,
          //   ),
          // );
        }
      },
      child: Column(
        children: [
          FTextFormField.email(
            label: Text(AppLocalizations.of(context)!.emailLabel),
            controller: emailController,
          ),
          const SizedBox(height: 10),
          FTextFormField.password(
            label: Text(AppLocalizations.of(context)!.passwordLabel),
            controller: passwordController,
          ),
          const SizedBox(height: 20),
          BlocBuilder<LoginBloc, LoginState>(
            builder: (context, state) {
              if (state is LoginLoading) {
                return const CircularProgressIndicator();
              }
              return FButton(
                onPress: () {
                  final email = emailController.text;
                  final password = passwordController.text;

                  context.read<LoginBloc>().add(
                    Login(email: email, password: password),
                  );
                },
                child: Text(AppLocalizations.of(context)!.loginButton),
              );
            },
          ),
        ],
      ),
    );
  }
}
