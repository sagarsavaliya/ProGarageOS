import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/integration_models.dart';

class IntegrationsRepository {
  final Dio _dio;

  const IntegrationsRepository({required Dio dio}) : _dio = dio;

  Future<WhatsAppIntegrationModel> fetchWhatsApp() async {
    final response = await _dio.get('/integrations/whatsapp');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return WhatsAppIntegrationModel.fromJson(data);
  }

  Future<WhatsAppIntegrationModel> updateWhatsApp(Map<String, dynamic> payload) async {
    final response = await _dio.put('/integrations/whatsapp', data: payload);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return WhatsAppIntegrationModel.fromJson(data);
  }

  Future<String> testWhatsApp() async {
    final response = await _dio.post('/integrations/whatsapp/test');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>? ?? {};
    return data['message'] as String? ?? 'Connection test completed.';
  }
}

final integrationsRepositoryProvider = Provider<IntegrationsRepository>((ref) {
  return IntegrationsRepository(dio: ref.watch(apiClientProvider));
});
