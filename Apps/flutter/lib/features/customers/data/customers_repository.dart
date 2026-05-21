import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/customer_models.dart';

class CustomersRepository {
  final Dio _dio;

  const CustomersRepository(this._dio);

  /// POST /customers — create or link customer to tenant garage.
  Future<Customer> createCustomer({
    required String firstName,
    required String lastName,
    required String phonePrimary,
    String? email,
    String? phoneSecondary,
    bool marketingOptIn = false,
    String? internalNotes,
  }) async {
    final response = await _dio.post(
      '/customers',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_primary': phonePrimary,
        if (email != null) 'email': email,
        if (phoneSecondary != null) 'phone_secondary': phoneSecondary,
        'marketing_opt_in': marketingOptIn,
        if (internalNotes != null) 'internal_notes': internalNotes,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Customer.fromJson(data);
  }

  /// POST /vehicles — register vehicle for customer (customer_uuid in body).
  Future<Vehicle> createVehicle({
    required String customerUuid,
    required String registrationNumber,
    required String maker,
    required String model,
    String? variant,
    int? year,
    String? color,
    String fuelType = 'petrol',
    String transmission = 'manual',
    int? odometerReading,
  }) async {
    final response = await _dio.post(
      '/vehicles',
      data: {
        'customer_uuid': customerUuid,
        'registration_number': registrationNumber.toUpperCase(),
        'maker': maker,
        'model': model,
        if (variant != null && variant.isNotEmpty) 'variant': variant,
        if (year != null) 'year': year,
        if (color != null && color.isNotEmpty) 'color': color,
        'fuel_type': fuelType,
        'transmission': transmission,
        if (odometerReading != null) 'odometer_reading': odometerReading,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  /// GET /customers — paginated, searchable list.
  Future<PaginatedCustomers> fetchCustomers({
    String? search,
    int page = 1,
    int perPage = 25,
    String sort = 'last_visited_at',
  }) async {
    final response = await _dio.get(
      '/customers',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
        'sort': sort,
      },
    );
    return PaginatedCustomers.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /customers/{uuid} — full customer detail with vehicles + recent jobs.
  Future<CustomerDetail> fetchCustomer(String uuid) async {
    final response = await _dio.get('/customers/$uuid');
    return CustomerDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /customers/{uuid}
  Future<CustomerDetail> updateCustomer({
    required String uuid,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneSecondary,
    bool? marketingOptIn,
    String? internalNotes,
  }) async {
    final response = await _dio.patch(
      '/customers/$uuid',
      data: {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (phoneSecondary != null) 'phone_secondary': phoneSecondary,
        if (marketingOptIn != null) 'marketing_opt_in': marketingOptIn,
        if (internalNotes != null) 'internal_notes': internalNotes,
      },
    );
    return CustomerDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /vehicles/{uuid}
  Future<Vehicle> updateVehicle({
    required String uuid,
    String? maker,
    String? model,
    String? variant,
    int? year,
    String? color,
    String? fuelType,
    int? odometerReading,
  }) async {
    final response = await _dio.patch(
      '/vehicles/$uuid',
      data: {
        if (maker != null) 'maker': maker,
        if (model != null) 'model': model,
        if (variant != null) 'variant': variant,
        if (year != null) 'year': year,
        if (color != null) 'color': color,
        if (fuelType != null) 'fuel_type': fuelType,
        if (odometerReading != null) 'odometer_reading': odometerReading,
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Vehicle.fromJson(data);
  }

  /// GET /customers/{uuid}/service-history
  Future<List<ServiceHistoryItem>> fetchServiceHistory(String customerUuid) async {
    final response = await _dio.get('/customers/$customerUuid/service-history');
    final list = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return list.map((e) => ServiceHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /vehicles/{uuid}/documents (multipart)
  Future<VehicleDocument> uploadVehicleDocument({
    required String vehicleUuid,
    required String documentType,
    required File file,
    String? documentNumber,
    String? expiryDate,
  }) async {
    final formData = FormData.fromMap({
      'document_type': documentType,
      if (documentNumber != null && documentNumber.isNotEmpty) 'document_number': documentNumber,
      if (expiryDate != null && expiryDate.isNotEmpty) 'expiry_date': expiryDate,
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split(RegExp(r'[/\\]')).last),
    });
    final response = await _dio.post(
      '/vehicles/$vehicleUuid/documents',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return VehicleDocument.fromJson(data);
  }

  /// GET /customers/{customer_uuid}/vehicles — vehicle list for a customer.
  Future<List<Vehicle>> fetchVehicles(String customerUuid) async {
    final response = await _dio.get('/customers/$customerUuid/vehicles');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /vehicles/{uuid}/documents — compliance documents for a vehicle.
  Future<List<VehicleDocument>> fetchDocuments(String vehicleUuid) async {
    final response = await _dio.get('/vehicles/$vehicleUuid/documents');
    final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return data.map((e) => VehicleDocument.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(apiClientProvider));
});
