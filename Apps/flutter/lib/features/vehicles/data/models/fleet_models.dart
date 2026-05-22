// Fleet vehicle list — GET /api/vehicles

class FleetVehicle {
  final String uuid;
  final String registrationNumber;
  final String displayName;
  final String maker;
  final String model;
  final String? variant;
  final int? year;
  final String? fuelType;
  final String? color;
  final int? odometerReading;
  final FleetVehicleCustomer? customer;

  const FleetVehicle({
    required this.uuid,
    required this.registrationNumber,
    required this.displayName,
    required this.maker,
    required this.model,
    this.variant,
    this.year,
    this.fuelType,
    this.color,
    this.odometerReading,
    this.customer,
  });

  String get makeModel {
    final base = '$maker $model';
    return year != null ? '$base · $year' : base;
  }

  factory FleetVehicle.fromJson(Map<String, dynamic> json) => FleetVehicle(
        uuid: json['uuid'] as String? ?? '',
        registrationNumber: json['registration_number'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        maker: json['maker'] as String? ?? '',
        model: json['model'] as String? ?? '',
        variant: json['variant'] as String?,
        year: (json['year'] as num?)?.toInt(),
        fuelType: json['fuel_type'] as String?,
        color: json['color'] as String?,
        odometerReading: (json['odometer_reading'] as num?)?.toInt(),
        customer: json['customer'] != null
            ? FleetVehicleCustomer.fromJson(json['customer'] as Map<String, dynamic>)
            : null,
      );
}

class FleetVehicleCustomer {
  final String uuid;
  final String name;
  final String? phone;

  const FleetVehicleCustomer({
    required this.uuid,
    required this.name,
    this.phone,
  });

  factory FleetVehicleCustomer.fromJson(Map<String, dynamic> json) =>
      FleetVehicleCustomer(
        uuid: json['uuid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
      );
}

class PaginatedFleetVehicles {
  final List<FleetVehicle> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedFleetVehicles({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedFleetVehicles.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedFleetVehicles(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => FleetVehicle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}
