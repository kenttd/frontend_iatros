// login_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iatros/src/features/login/bloc/login_event.dart';
import 'package:iatros/src/features/login/bloc/login_state.dart';
import 'package:iatros/src/utils/auth_service.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState>{
  final AuthService auth;

  LoginBloc(this.auth): super(LoginState()) {
    on<Login>((event, emit) async {
      emit(LoginLoading());
      try {
        final credential = await auth.signIn(
          email: event.email,
          password: event.password,
        );
        emit(LoginSuccess(credential.user!));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });

    on<Register>((event, emit) async {
      emit(LoginLoading()); // Add loading state
      try {
        final credential = await auth.createAccount(
            email: event.email,
            password: event.password,
            displayname: event.displayname
        );
        emit(LoginSuccess(credential.user!)); // Emit success state
      } catch (e) {
        emit(LoginFailure(e.toString())); // Handle errors
        print('Registration error: $e'); // Debug print
      }
    });
  }
}