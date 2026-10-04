import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Current logged-in user
  User? get currentUser => _auth.currentUser;

  // Login
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Forgot Password
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Google Sign-In did not return an ID token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return await _auth.signInWithCredential(credential);
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool get supportsPasswordChange =>
      currentUser?.providerData.any(
        (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    if (!supportsPasswordChange) {
      throw FirebaseAuthException(code: 'operation-not-allowed');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
