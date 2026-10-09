import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/device_notification_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? _userProfile;
  bool _isProfileLoading = false;
  String? _profileError;
  StreamSubscription<Map<String, dynamic>?>? _profileSubscription;
  bool _isProfileSaving = false;
  bool _isPhotoUploading = false;
  bool _isPasswordChanging = false;
  String? _accountError;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;

  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isProfileLoading => _isProfileLoading;
  String? get profileError => _profileError;
  bool get isProfileSaving => _isProfileSaving;
  bool get isPhotoUploading => _isPhotoUploading;
  bool get isPasswordChanging => _isPasswordChanging;
  String? get accountError => _accountError;

  String get fullName => _userProfile?['fullName']?.toString() ?? '';
  String get email =>
      currentUser?.email ?? _userProfile?['email']?.toString() ?? '';
  String get phone => _userProfile?['phone']?.toString() ?? '';
  String get photoUrl => _userProfile?['photoUrl']?.toString() ?? '';
  bool get supportsPasswordChange => _authService.supportsPasswordChange;

  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signIn(email: email, password: password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user;

      if (user == null) {
        _errorMessage = 'Unable to sign in with Google.';
        _setLoading(false);
        return false;
      }

      final existingProfile = await _userService.getUserProfile(user.uid);

      if (existingProfile == null) {
        await _userService.createUserProfile(
          uid: user.uid,
          fullName: user.displayName ?? '',
          email: user.email ?? '',
          phone: user.phoneNumber ?? '',
        );
      }

      await loadUserProfile();

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _errorMessage = 'Unable to sign in with Google. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userCredential = await _authService.signUp(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        _errorMessage = 'Unable to create user account.';
        _setLoading(false);
        return false;
      }

      await _userService.createUserProfile(
        uid: user.uid,
        fullName: fullName,
        email: email,
        phone: phone,
      );

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Sign up error: $e');
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.sendPasswordResetEmail(email: email);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e);
      _setLoading(false);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadUserProfile() async {
    final user = currentUser;

    if (user == null) {
      _userProfile = null;
      _profileError = 'No authenticated user found.';
      notifyListeners();
      return;
    }

    await _profileSubscription?.cancel();
    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();

    _profileSubscription = _userService
        .watchUserProfile(user.uid)
        .listen(
          (profile) {
            if (profile == null) {
              _userProfile = null;
              _profileError = 'Profile information is not available.';
            } else {
              _userProfile = profile;
              _profileError = null;
            }
            _isProfileLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('Profile loading error: $error');
            _userProfile = null;
            _profileError = 'Unable to load profile information.';
            _isProfileLoading = false;
            notifyListeners();
          },
        );
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = currentUser;
    if (user == null) {
      _accountError = 'You must be signed in to update your profile.';
      notifyListeners();
      return false;
    }
    _isProfileSaving = true;
    _accountError = null;
    notifyListeners();
    try {
      await _userService.updateUserProfile(
        uid: user.uid,
        fullName: fullName,
        phone: phone,
      );
      return true;
    } catch (error) {
      debugPrint('Profile update error: $error');
      _accountError = 'Unable to update profile. Please try again.';
      return false;
    } finally {
      _isProfileSaving = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = currentUser;
    if (user == null) {
      _accountError = 'You must be signed in to change your profile photo.';
      notifyListeners();
      return false;
    }
    _isPhotoUploading = true;
    _accountError = null;
    notifyListeners();
    try {
      final url = await _userService.uploadProfileImage(
        bytes: bytes,
        fileName: fileName,
      );
      await _userService.updateProfilePhoto(uid: user.uid, photoUrl: url);
      return true;
    } catch (error) {
      debugPrint('Profile photo update error: $error');
      _accountError = 'Unable to update profile photo. Please try again.';
      return false;
    } finally {
      _isPhotoUploading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isPasswordChanging = true;
    _accountError = null;
    notifyListeners();
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on FirebaseAuthException catch (error) {
      _accountError = _getPasswordErrorMessage(error);
      return false;
    } catch (error) {
      debugPrint('Password change error: $error');
      _accountError = 'Unable to change password. Please try again.';
      return false;
    } finally {
      _isPasswordChanging = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await DeviceNotificationService.instance.unregisterCurrentToken();
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    await _authService.signOut();

    _userProfile = null;
    _profileError = null;
    _isProfileLoading = false;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _getPasswordErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'The current password is incorrect.';
      case 'weak-password':
        return 'The new password must contain at least 6 characters.';
      case 'requires-recent-login':
        return 'Please sign in again before changing your password.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Password changes are not available for this sign-in method.';
      case 'user-not-found':
        return 'You must be signed in to change your password.';
      default:
        return 'Unable to change password. Please try again.';
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
