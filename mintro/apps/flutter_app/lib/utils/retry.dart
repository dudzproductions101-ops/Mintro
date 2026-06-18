import 'dart:math';

/// Exponential backoff retry wrapper for API calls that may transiently fail
/// (network blip, 503 from a cold-start backend, etc.).
///
/// Usage:
/// ```dart
/// final result = await withRetry(() => ApiClient.instance.post('/lessons/$id/complete', body));
/// ```
///
/// Only retries on connection errors and 5xx responses — never on 4xx
/// (bad request, unauthorized, etc.) since retrying those won't help and
/// would just delay surfacing the real error to the user.
Future<T> withRetry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
}) async {
  int attempt = 0;
  Duration delay = initialDelay;

  while (true) {
    try {
      return await fn();
    } catch (e) {
      attempt++;

      final isRetryable = _isRetryable(e);
      if (!isRetryable || attempt >= maxAttempts) {
        rethrow;
      }

      // Jitter: add up to 20% of the delay randomly to avoid thundering herd
      final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.2 * Random().nextDouble()).round());
      await Future.delayed(delay + jitter);
      delay = delay * 2; // exponential backoff
    }
  }
}

bool _isRetryable(Object error) {
  final msg = error.toString().toLowerCase();
  // Connection errors, timeouts, and 5xx ApiExceptions
  return msg.contains('socketexception') ||
      msg.contains('connection') ||
      msg.contains('timeout') ||
      msg.contains('ApiException(5'); // matches ApiException(503, ...), (502, ...) etc.
}
