import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:iatros/src/features/login/bloc/login_bloc.dart';
import 'package:iatros/src/features/login/bloc/login_event.dart';
import 'package:iatros/src/features/login/bloc/login_state.dart';
import 'package:local_auth/local_auth.dart';
import 'package:iatros/l10n/arb/app_localizations.dart';

final LocalAuthentication auth = LocalAuthentication();

class RegisterPage extends StatefulWidget {
  final LoginBloc loginBloc;
  const RegisterPage({super.key, required this.loginBloc});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController dnController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      bloc: widget.loginBloc,
      listener: (context, state) {
        if (state is LoginSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
          context.go("/home");
        } else if (state is LoginFailure) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Error: ${state.error}')),
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
          const SizedBox(height: 10),
          FTextFormField(
            label: const Text("Display Name"),
            controller: dnController,
          ),
          const SizedBox(height: 20),
          BlocBuilder<LoginBloc, LoginState>(
            bloc: widget.loginBloc,
            builder: (context, state) {
              if (state is LoginLoading) {
                return const CircularProgressIndicator();
              }
              return FButton(
                onPress: () {
                  register();
                },
                child: Text(AppLocalizations.of(context)!.registerTitle),
              );
            },
          ),
          FButton(
            onPress: () async {
              final bool authenticated = await auth.authenticate(
                localizedReason: 'Please authenticate',
              );
              print("authenticated: $authenticated");
            },
            child: const Text("Authenticate"),
          ),
        ],
      ),
    );
  }

  void register() {
    widget.loginBloc.add(
      Register(
        email: emailController.text,
        password: passwordController.text,
        displayname: dnController.text,
      ),
    );
  }
}
