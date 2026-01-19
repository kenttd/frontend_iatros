abstract class LoginEvent {}

class Login extends LoginEvent {
  final String email;
  final String password;

  Login({
    required this.email,
    required this.password,
  });
}

class Register extends LoginEvent{
  final String email;
  final String password;
  final String displayname;

  Register({
    required this.email,
    required this.password,
    required this.displayname,
  });
}
