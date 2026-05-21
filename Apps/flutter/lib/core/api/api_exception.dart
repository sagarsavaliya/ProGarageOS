import 'package:dio/dio.dart';

/// User-facing API failure parsed from [DioException] or other errors.
class ApiFailure implements Exception {
  final String message;
  final bool isRetryable;
  final int? statusCode;

  const ApiFailure({
    required this.message,
    required this.isRetryable,
    this.statusCode,
  });

  factory ApiFailure.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _messageFromResponse(e) ?? _messageFromType(e);

    return ApiFailure(
      message: message,
      isRetryable: _isRetryable(e, statusCode),
      statusCode: statusCode,
    );
  }

  static bool _isRetryable(DioException e, int? statusCode) {
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return false;
    }
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return true;
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }

  static String? _messageFromResponse(DioException e) {
    final data = e.response?.data;
    if (data is! Map<String, dynamic>) return null;

    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final msg = error['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;

    return null;
  }

  static String _messageFromType(DioException e) {
    final statusCode = e.response?.statusCode;

    if (statusCode == 401) {
      return 'Your session expired. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to do that.';
    }
    if (statusCode == 404) {
      return 'The requested item was not found.';
    }
    if (statusCode == 422) {
      return 'Some details are invalid. Please check and try again.';
    }
    if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
      return 'Server is temporarily unavailable. Please try again.';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach server. Check your network.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        return 'Something went wrong. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again later.';
      case DioExceptionType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() => message;
}
