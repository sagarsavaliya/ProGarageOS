import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/env.dart';
import '../storage/secure_storage.dart';
import 'retry_interceptor.dart';

part 'api_client.g.dart';

@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(RetryInterceptor(dio));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(secureStorageProvider).getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // 401 → clear token, router will redirect to login
        if (error.response?.statusCode == 401) {
          ref.read(secureStorageProvider).clearToken();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
