import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'models/appointment_models.dart';

class AppointmentsRepository {
  final Dio _dio;

  const AppointmentsRepository(this._dio);

  Future<PaginatedAppointments> fetchAppointments({
    String? date,
    String? status,
    bool upcoming = false,
    int page = 1,
  }) async {
    final response = await _dio.get(
      '/appointments',
      queryParameters: {
        'page': page,
        'per_page': 25,
        if (date != null) 'date': date,
        if (status != null) 'status': status,
        if (upcoming) 'upcoming': '1',
      },
    );
    return PaginatedAppointments.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Appointment> bookAppointment({
    required String customerUuid,
    required String vehicleUuid,
    required String scheduledDate,
    required String startTime,
    String? endTime,
    String? serviceCategoryUuid,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/appointments',
      data: {
        'customer_uuid': customerUuid,
        'vehicle_uuid': vehicleUuid,
        'scheduled_date': scheduledDate,
        'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (serviceCategoryUuid != null) 'service_category_uuid': serviceCategoryUuid,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'source': 'phone',
      },
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return Appointment.fromJson(data);
  }

  Future<AppointmentCheckInResult> checkIn({
    required String appointmentUuid,
    int? odometerAtIntake,
    String? fuelLevel,
  }) async {
    final response = await _dio.put(
      '/appointments/$appointmentUuid/check-in',
      data: {
        if (odometerAtIntake != null) 'odometer_at_intake': odometerAtIntake,
        if (fuelLevel != null) 'fuel_level': fuelLevel,
      },
    );
    return AppointmentCheckInResult.fromJson(response.data as Map<String, dynamic>);
  }
}

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository(ref.watch(apiClientProvider));
});
