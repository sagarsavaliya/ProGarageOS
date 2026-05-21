import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Extract API error code from a Dio response envelope.
String? apiErrorCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        return err['code'] as String?;
      }
    }
  }
  return null;
}

/// Returns a plain-English message for any API or network error.
String failureMessage(Object error) {
  if (error is ApiFailure) return error.message;
  if (error is DioException) {
    return ApiFailure.fromDioException(error).message;
  }
  return 'Something went wrong. Please try again.';
}
