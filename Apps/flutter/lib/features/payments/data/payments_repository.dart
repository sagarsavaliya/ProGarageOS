import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/outstanding_models.dart';

class PaymentsRepository {
  final Dio _dio;

  const PaymentsRepository(this._dio);

  Future<OutstandingSummary> fetchOutstanding({String? search, int page = 1}) async {
    final response = await _dio.get(
      '/payments/outstanding',
      queryParameters: {
        'page': page,
        'per_page': 25,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return OutstandingSummary.fromJson(response.data as Map<String, dynamic>);
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(apiClientProvider));
});
