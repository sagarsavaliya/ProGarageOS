import 'package:dio/dio.dart';

const _retryCountKey = 'retry_count';
const _maxRetries = 3;
const _retryableMethods = {'GET', 'PATCH', 'POST'};
const _retryableStatusCodes = {502, 503, 504};

/// Retries transient failures for GET/PATCH/POST with exponential backoff.
class RetryInterceptor extends Interceptor {
  final Dio _dio;

  RetryInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final options = err.requestOptions;
    final retryCount = (options.extra[_retryCountKey] as int?) ?? 0;
    if (retryCount >= _maxRetries) {
      return handler.next(err);
    }

    options.extra[_retryCountKey] = retryCount + 1;
    final delaySeconds = [1, 2, 4][retryCount];
    await Future<void>.delayed(Duration(seconds: delaySeconds));

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    if (!_retryableMethods.contains(method)) {
      return false;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null) {
      if (statusCode >= 400 && statusCode < 500) {
        return false;
      }
      if (_retryableStatusCodes.contains(statusCode)) {
        return true;
      }
      return false;
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }
}
