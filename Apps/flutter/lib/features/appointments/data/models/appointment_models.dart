class AppointmentCustomer {
  final String uuid;
  final String name;
  final String? phone;

  const AppointmentCustomer({required this.uuid, required this.name, this.phone});

  factory AppointmentCustomer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppointmentCustomer(uuid: '', name: '—');
    return AppointmentCustomer(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '—',
      phone: json['phone'] as String?,
    );
  }
}

class AppointmentVehicle {
  final String uuid;
  final String registrationNumber;
  final String? display;

  const AppointmentVehicle({
    required this.uuid,
    required this.registrationNumber,
    this.display,
  });

  factory AppointmentVehicle.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AppointmentVehicle(uuid: '', registrationNumber: '—');
    }
    return AppointmentVehicle(
      uuid: json['uuid'] as String? ?? '',
      registrationNumber: json['registration_number'] as String? ?? '—',
      display: json['display'] as String?,
    );
  }
}

class AppointmentCategory {
  final String uuid;
  final String name;

  const AppointmentCategory({required this.uuid, required this.name});

  factory AppointmentCategory.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppointmentCategory(uuid: '', name: '');
    return AppointmentCategory(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class Appointment {
  final String uuid;
  final String appointmentNumber;
  final String status;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final String? notes;
  final String? convertedJobUuid;
  final AppointmentCustomer customer;
  final AppointmentVehicle vehicle;
  final AppointmentCategory? serviceCategory;

  const Appointment({
    required this.uuid,
    required this.appointmentNumber,
    required this.status,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.convertedJobUuid,
    required this.customer,
    required this.vehicle,
    this.serviceCategory,
  });

  bool get canCheckIn => status == 'booked' || status == 'confirmed';

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      uuid: json['uuid'] as String? ?? '',
      appointmentNumber: json['appointment_number'] as String? ?? '',
      status: json['status'] as String? ?? 'booked',
      scheduledDate: DateTime.tryParse(json['scheduled_date'] as String? ?? '') ?? DateTime.now(),
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      notes: json['notes'] as String?,
      convertedJobUuid: json['converted_job_uuid'] as String?,
      customer: AppointmentCustomer.fromJson(json['customer'] as Map<String, dynamic>?),
      vehicle: AppointmentVehicle.fromJson(json['vehicle'] as Map<String, dynamic>?),
      serviceCategory: json['service_category'] != null
          ? AppointmentCategory.fromJson(json['service_category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AppointmentCheckInResult {
  final String appointmentUuid;
  final String jobUuid;
  final String jobNumber;

  const AppointmentCheckInResult({
    required this.appointmentUuid,
    required this.jobUuid,
    required this.jobNumber,
  });

  factory AppointmentCheckInResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final job = data['job'] as Map<String, dynamic>? ?? {};
    return AppointmentCheckInResult(
      appointmentUuid: data['appointment_uuid'] as String? ?? '',
      jobUuid: job['uuid'] as String? ?? '',
      jobNumber: job['job_number'] as String? ?? '',
    );
  }
}

class PaginatedAppointments {
  final List<Appointment> items;
  final int total;
  final bool hasMore;
  final int currentPage;

  const PaginatedAppointments({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.currentPage,
  });

  factory PaginatedAppointments.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final current = (meta['current_page'] as num?)?.toInt() ?? 1;
    final last = (meta['last_page'] as num?)?.toInt() ?? 1;
    return PaginatedAppointments(
      items: data.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList(),
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      hasMore: current < last,
      currentPage: current,
    );
  }
}
