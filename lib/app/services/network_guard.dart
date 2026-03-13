import 'dart:async';

class NetworkGuard {
  static const Duration defaultTimeout = Duration(seconds: 12);

  static Future<T> run<T>(
    Future<T> future, {
    Duration timeout = defaultTimeout,
    String? message,
  }) {
    return future.timeout(
      timeout,
      onTimeout: () =>
          throw TimeoutException(message ?? _defaultTimeoutMessage),
    );
  }

  static const String _defaultTimeoutMessage =
      'Request timed out. Please check your internet connection and try again.';
}
