import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Add this import

class AuthService extends ChangeNotifier { // Add ChangeNotifier
  // Private constructor
  AuthService._() {
    // Listen to auth state changes and notify GoRouter
    firebaseAuth.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  // Single instance
  static final AuthService _instance = AuthService._();

  // Factory constructor returns the same instance
  factory AuthService() => _instance;

  // Firebase Auth instance
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChange => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
    required String displayname,
  }) async {
    UserCredential userCredential =
    await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName(displayname);
      await user.reload();
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }
}