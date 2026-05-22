import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/invoice_models.dart';

class InvoicesRepository {
  final Dio _dio;

  const InvoicesRepository(this._dio);

  /// GET /api/invoices — paginated, filterable list.
  Future<PaginatedInvoices> fetchInvoices({
    int page = 1,
    String? status,
    String? search,
  }) async {
    final response = await _dio.get(
      '/invoices',
      queryParameters: {
        'page': page,
        'per_page': 20,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedInvoices.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/invoices/{uuid} — full invoice detail with items + payments.
  Future<InvoiceDetail> fetchInvoice(String uuid) async {
    final response = await _dio.get('/invoices/$uuid');
    return InvoiceDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /invoices — create invoice from job.
  Future<CreatedInvoice> createInvoice(Map<String, dynamic> body) async {
    final response = await _dio.post('/invoices', data: body);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return CreatedInvoice(
      uuid: data['uuid'] as String? ?? '',
      invoiceNumber: data['invoice_number'] as String? ?? 'INV-NEW',
    );
  }

  /// POST /invoices/{uuid}/payments — record a payment against an invoice.
  Future<InvoiceDetail> recordPayment(String uuid, RecordPaymentRequest request) async {
    await _dio.post(
      '/invoices/$uuid/payments',
      data: request.toJson(),
    );
    return fetchInvoice(uuid);
  }

  Future<InvoiceDetail> updateSplitBilling(
    String uuid, {
    required double customerPayAmount,
    required double insuranceClaimAmount,
  }) async {
    await _dio.patch(
      '/invoices/$uuid/split-billing',
      data: {
        'customer_pay_amount': customerPayAmount,
        'insurance_claim_amount': insuranceClaimAmount,
      },
    );
    return fetchInvoice(uuid);
  }

  /// GET /invoices/{uuid}/pdf — generate or return invoice PDF URL.
  Future<String> fetchInvoicePdfUrl(String uuid) async {
    final response = await _dio.get('/invoices/$uuid/pdf');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final url = data['pdf_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Invoice PDF is not available yet. Try again in a moment.');
    }
    return url;
  }

  /// GET /api/payment-methods — list available payment methods.
  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final response = await _dio.get('/payment-methods');
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class CreatedInvoice {
  final String uuid;
  final String invoiceNumber;

  const CreatedInvoice({required this.uuid, required this.invoiceNumber});
}

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(ref.watch(apiClientProvider));
});
