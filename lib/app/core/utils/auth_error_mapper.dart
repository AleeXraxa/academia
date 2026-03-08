import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  AuthErrorMapper._();

  static String loginMessage(FirebaseAuthException e) {
    final String code = _normalizeCode(e.code);
    switch (code) {
      case 'invalid-email':
        return 'The email address format is not valid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-login-credentials':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled. Contact administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'internal-error':
        return _inferFriendlyMessage(e.message) ??
            'Authentication service is temporarily unavailable. Please try again.';
      case 'unknown-error':
      case 'unknown':
        return _inferFriendlyMessage(e.message) ??
            'Incorrect email or password.';
      case 'channel-error':
        return 'Could not connect to authentication service. Please try again.';
      default:
        return _inferFriendlyMessage(e.message) ?? 'Login failed. Please try again.';
    }
  }

  static String registerMessage(FirebaseAuthException e) {
    final String code = _normalizeCode(e.code);
    switch (code) {
      case 'invalid-email':
        return 'The email address format is not valid.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password registration is not enabled.';
      case 'too-many-requests':
        return 'Too many requests. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'internal-error':
        return _inferFriendlyMessage(e.message) ??
            'Registration service is temporarily unavailable. Please try again.';
      case 'unknown-error':
      case 'unknown':
        return _inferFriendlyMessage(e.message) ??
            'Registration failed. Please check your details and try again.';
      case 'channel-error':
        return 'Could not connect to registration service. Please try again.';
      default:
        return _inferFriendlyMessage(e.message) ??
            'Registration failed. Please try again.';
    }
  }

  static String _normalizeCode(String raw) {
    final String value = raw.trim().toLowerCase();
    return value.startsWith('auth/') ? value.substring(5) : value;
  }

  static String? _inferFriendlyMessage(String? rawMessage) {
    if (rawMessage == null || rawMessage.trim().isEmpty) {
      return null;
    }

    final String message = rawMessage.toUpperCase();

    if (message.contains('INVALID_LOGIN_CREDENTIALS') ||
        message.contains('WRONG_PASSWORD') ||
        message.contains('USER_NOT_FOUND')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('INVALID_EMAIL')) {
      return 'The email address format is not valid.';
    }
    if (message.contains('EMAIL_ALREADY_IN_USE')) {
      return 'An account already exists with this email.';
    }
    if (message.contains('WEAK_PASSWORD')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (message.contains('NETWORK_REQUEST_FAILED')) {
      return 'Network error. Check your internet connection.';
    }

    return null;
  }
}
