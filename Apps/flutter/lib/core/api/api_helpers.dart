import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Returns a plain-English message for any API or network error.
String failureMessage(Object error) {
  if (error is ApiFailure) return error.message;
  if (error is DioException) {
    return ApiFailure.fromDioException(error).message;
  }
  return 'Something went wrong. Please try again.';
}
