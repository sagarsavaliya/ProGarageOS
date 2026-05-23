// Customer + Vehicle data models — aligned with GET /customers, GET /customers/{uuid},
// GET /customers/{uuid}/vehicles, GET /vehicles/{uuid}/documents API contracts.

import '../../../../core/utils/json_parsing.dart';

// ---------------------------------------------------------------------------
// Customer (list item)
// ---------------------------------------------------------------------------

class GarageProfile {
  final int loyaltyPoints;
  final double totalSpent;
  final int visitCount;
  final DateTime? lastVisitedAt;
  final String? preferredTechnicianName;
  final String? internalNotes;

  const GarageProfile({
    required this.loyaltyPoints,
    required this.totalSpent,
    required this.visitCount,
    this.lastVisitedAt,
    this.preferredTechnicianName,
    this.internalNotes,
  });

  factory GarageProfile.fromJson(Map<String, dynamic> json) => GarageProfile(
        loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
        totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
        visitCount: (json['visit_count'] as num?)?.toInt() ?? 0,
        lastVisitedAt: json['last_visited_at'] != null
            ? DateTime.tryParse(json['last_visited_at'] as String)
            : null,
        preferredTechnicianName:
            (json['preferred_technician'] as Map<String, dynamic>?)?['name'] as String?,
        internalNotes: json['internal_notes'] as String?,
      );
}

class Customer {
  final String uuid;
  final String firstName;
  final String lastName;
  final String phonePrimary;
  final String? phoneSecondary;
  final String? email;
  final String preferredLanguage;
  final GarageProfile garageProfile;
  final int vehiclesCount;
  final bool isActive;

  const Customer({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.phonePrimary,
    this.phoneSecondary,
    this.email,
    required this.preferredLanguage,
    required this.garageProfile,
    required this.vehiclesCount,
    required this.isActive,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        uuid: json['uuid'] as String? ?? '',
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        phonePrimary: json['phone_primary'] as String? ?? '',
        phoneSecondary: json['phone_secondary'] as String?,
        email: json['email'] as String?,
        preferredLanguage: json['preferred_language'] as String? ?? 'en',
        garageProfile:
            GarageProfile.fromJson(json['garage_profile'] as Map<String, dynamic>? ?? {}),
        vehiclesCount: (json['vehicles_count'] as num?)?.toInt() ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );
}

// ---------------------------------------------------------------------------
// CustomerDetail — full response from GET /customers/{uuid}
// ---------------------------------------------------------------------------

class CustomerVehicleSummary {
  final String uuid;
  final String registrationNumber;
  final String maker;
  final String model;
  final int year;
  final String fuelType;
  final String? color;
  final int? odometerReading;

  const CustomerVehicleSummary({
    required this.uuid,
    required this.registrationNumber,
    required this.maker,
    required this.model,
    required this.year,
    required this.fuelType,
    this.color,
    this.odometerReading,
  });

  String get makeModel => '$maker $model $year';

  factory CustomerVehicleSummary.fromJson(Map<String, dynamic> json) => CustomerVehicleSummary(
        uuid: json['uuid'] as String? ?? '',
        registrationNumber: json['registration_number'] as String? ?? '',
        maker: json['maker'] as String? ?? '',
        model: json['model'] as String? ?? '',
        year: jsonAsInt(json['year']),
        fuelType: json['fuel_type'] as String? ?? '',
        color: json['color'] as String?,
        odometerReading: jsonAsIntOrNull(json['odometer_reading']),
      );
}

/// Timeline entry from GET /customers/{uuid}/service-history
class ServiceHistoryItem {
  final String type; // job | invoice
  final String uuid;
  final String title;
  final String? subtitle;
  final String status;
  final double? amount;
  final DateTime? occurredAt;

  const ServiceHistoryItem({
    required this.type,
    required this.uuid,
    required this.title,
    this.subtitle,
    required this.status,
    this.amount,
    this.occurredAt,
  });

  factory ServiceHistoryItem.fromJson(Map<String, dynamic> json) => ServiceHistoryItem(
        type: json['type'] as String? ?? 'job',
        uuid: json['uuid'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        status: json['status'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble(),
        occurredAt: json['occurred_at'] != null
            ? DateTime.tryParse(json['occurred_at'] as String)
            : null,
      );
}

class RecentJobSummary {
  final String uuid;
  final String jobNumber;
  final String status;
  final DateTime? createdAt;

  const RecentJobSummary({
    required this.uuid,
    required this.jobNumber,
    required this.status,
    this.createdAt,
  });

  factory RecentJobSummary.fromJson(Map<String, dynamic> json) => RecentJobSummary(
        uuid: json['uuid'] as String? ?? '',
        jobNumber: json['job_number'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class CustomerDetail {
  final String uuid;
  final String firstName;
  final String lastName;
  final String phonePrimary;
  final String? phoneSecondary;
  final String? email;
  final String preferredLanguage;
  final bool marketingOptIn;
  final GarageProfile garageProfile;
  final List<CustomerVehicleSummary> vehicles;
  final List<RecentJobSummary> recentJobs;

  const CustomerDetail({
    required this.uuid,
    required this.firstName,
    required this.lastName,
    required this.phonePrimary,
    this.phoneSecondary,
    this.email,
    required this.preferredLanguage,
    required this.marketingOptIn,
    required this.garageProfile,
    required this.vehicles,
    required this.recentJobs,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return CustomerDetail(
      uuid: data['uuid'] as String? ?? '',
      firstName: data['first_name'] as String? ?? '',
      lastName: data['last_name'] as String? ?? '',
      phonePrimary: data['phone_primary'] as String? ?? '',
      phoneSecondary: data['phone_secondary'] as String?,
      email: data['email'] as String?,
      preferredLanguage: data['preferred_language'] as String? ?? 'en',
      marketingOptIn: data['marketing_opt_in'] as bool? ?? false,
      garageProfile:
          GarageProfile.fromJson(data['garage_profile'] as Map<String, dynamic>? ?? {}),
      vehicles: (data['vehicles'] as List<dynamic>?)
              ?.map((e) => CustomerVehicleSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentJobs: (data['recent_jobs'] as List<dynamic>?)
              ?.map((e) => RecentJobSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle (full — from GET /customers/{uuid}/vehicles)
// ---------------------------------------------------------------------------

class ComplianceAlert {
  final String type; // 'insurance' | 'puc' | 'fitness' | 'permit' | 'rc'
  final String status; // 'expired' | 'expiring_soon'
  final String? expiry;

  const ComplianceAlert({required this.type, required this.status, this.expiry});

  factory ComplianceAlert.fromJson(Map<String, dynamic> json) => ComplianceAlert(
        type: json['type'] as String? ?? '',
        status: json['status'] as String? ?? '',
        expiry: json['expiry'] as String?,
      );

  String get typeLabel => type.toUpperCase().replaceAll('_', ' ');

  bool get isExpired => status == 'expired';
}

class Vehicle {
  final String uuid;
  final String registrationNumber;
  final String? chassisNumber;
  final String? engineNumber;
  final String maker;
  final String model;
  final String? variant;
  final int year;
  final String? color;
  final String fuelType;
  final String? transmission;
  final String? bodyType;
  final String? emissionNorms;
  final int? odometerReading;
  final bool gpsTrackingConsent;
  final String? registrationDate;
  final String? registrationValidity;
  final String? insuranceExpiry;
  final String? fitnessValidity;
  final String? pucExpiry;
  final bool isActive;
  final String? photoUrl;
  final List<ComplianceAlert> complianceAlerts;
  final String? customerUuid;

  const Vehicle({
    required this.uuid,
    required this.registrationNumber,
    this.chassisNumber,
    this.engineNumber,
    required this.maker,
    required this.model,
    this.variant,
    required this.year,
    this.color,
    required this.fuelType,
    this.transmission,
    this.bodyType,
    this.emissionNorms,
    this.odometerReading,
    required this.gpsTrackingConsent,
    this.registrationDate,
    this.registrationValidity,
    this.insuranceExpiry,
    this.fitnessValidity,
    this.pucExpiry,
    required this.isActive,
    this.photoUrl,
    required this.complianceAlerts,
    this.customerUuid,
  });

  String get makeModel => '$maker $model${variant != null ? ' $variant' : ''} $year';

  bool get hasAlerts => complianceAlerts.isNotEmpty;

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        uuid: json['uuid'] as String? ?? '',
        registrationNumber: json['registration_number'] as String? ?? '',
        chassisNumber: json['chassis_number'] as String?,
        engineNumber: json['engine_number'] as String?,
        maker: json['maker'] as String? ?? '',
        model: json['model'] as String? ?? '',
        variant: json['variant'] as String?,
        year: jsonAsInt(json['year']),
        color: json['color'] as String?,
        fuelType: json['fuel_type'] as String? ?? '',
        transmission: json['transmission'] as String?,
        bodyType: json['body_type'] as String?,
        emissionNorms: json['emission_norms'] as String?,
        odometerReading: jsonAsIntOrNull(json['odometer_reading']),
        gpsTrackingConsent: json['gps_tracking_consent'] as bool? ?? false,
        registrationDate: json['registration_date'] as String?,
        registrationValidity: json['registration_validity'] as String?,
        insuranceExpiry: json['insurance_expiry'] as String?,
        fitnessValidity: json['fitness_validity'] as String?,
        pucExpiry: json['puc_expiry'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        photoUrl: json['photo_url'] as String?,
        complianceAlerts: (json['compliance_alerts'] as List<dynamic>?)
                ?.map((e) => ComplianceAlert.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        customerUuid: jsonAsMap(json['customer'])?['uuid'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Vehicle Document
// ---------------------------------------------------------------------------

class VehicleDocument {
  final String uuid;
  final String documentType;
  final String? documentNumber;
  final String? issuingAuthority;
  final String? issueDate;
  final String? expiryDate;
  final String? fileUrl;
  final bool isVerified;

  const VehicleDocument({
    required this.uuid,
    required this.documentType,
    this.documentNumber,
    this.issuingAuthority,
    this.issueDate,
    this.expiryDate,
    this.fileUrl,
    required this.isVerified,
  });

  String get typeLabel {
    switch (documentType) {
      case 'insurance':
        return 'Insurance';
      case 'puc':
        return 'Pollution Certificate';
      case 'fitness':
        return 'Fitness Certificate';
      case 'permit':
        return 'Vehicle Permit';
      case 'rc':
        return 'Registration Certificate';
      default:
        return documentType.toUpperCase();
    }
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    final expiry = DateTime.tryParse(expiryDate!);
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  factory VehicleDocument.fromJson(Map<String, dynamic> json) => VehicleDocument(
        uuid: json['uuid'] as String? ?? '',
        documentType: json['document_type'] as String? ?? '',
        documentNumber: json['document_number'] as String?,
        issuingAuthority: json['issuing_authority'] as String?,
        issueDate: json['issue_date'] as String?,
        expiryDate: json['expiry_date'] as String?,
        fileUrl: json['file_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// Paginated customers wrapper
// ---------------------------------------------------------------------------

class PaginatedCustomers {
  final List<Customer> customers;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedCustomers({
    required this.customers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedCustomers.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedCustomers(
      customers: (json['data'] as List<dynamic>?)
              ?.map((e) => Customer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Demo / fallback data
// ---------------------------------------------------------------------------

PaginatedCustomers get customersDemoData => PaginatedCustomers(
      currentPage: 1,
      lastPage: 1,
      total: 5,
      customers: [
        Customer(
          uuid: 'cst-demo-001',
          firstName: 'Rahul',
          lastName: 'Sharma',
          phonePrimary: '+919876543210',
          email: 'rahul.sharma@example.com',
          preferredLanguage: 'en',
          garageProfile: GarageProfile(
            loyaltyPoints: 1250,
            totalSpent: 48500,
            visitCount: 7,
            lastVisitedAt: DateTime.now().subtract(const Duration(days: 30)),
            preferredTechnicianName: 'Amit Kamble',
          ),
          vehiclesCount: 2,
          isActive: true,
        ),
        Customer(
          uuid: 'cst-demo-002',
          firstName: 'Priya',
          lastName: 'Patel',
          phonePrimary: '+919765432109',
          email: 'priya.patel@example.com',
          preferredLanguage: 'hi',
          garageProfile: GarageProfile(
            loyaltyPoints: 450,
            totalSpent: 18200,
            visitCount: 3,
            lastVisitedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
          vehiclesCount: 1,
          isActive: true,
        ),
        Customer(
          uuid: 'cst-demo-003',
          firstName: 'Vikram',
          lastName: 'Mehta',
          phonePrimary: '+918765432109',
          preferredLanguage: 'en',
          garageProfile: GarageProfile(
            loyaltyPoints: 2800,
            totalSpent: 125000,
            visitCount: 18,
            lastVisitedAt: DateTime.now().subtract(const Duration(days: 3)),
            preferredTechnicianName: 'Suresh More',
          ),
          vehiclesCount: 3,
          isActive: true,
        ),
        Customer(
          uuid: 'cst-demo-004',
          firstName: 'Sunita',
          lastName: 'Gupta',
          phonePrimary: '+917654321098',
          email: 'sunita.gupta@example.com',
          preferredLanguage: 'en',
          garageProfile: GarageProfile(
            loyaltyPoints: 600,
            totalSpent: 24000,
            visitCount: 4,
            lastVisitedAt: DateTime.now().subtract(const Duration(days: 60)),
          ),
          vehiclesCount: 1,
          isActive: true,
        ),
        Customer(
          uuid: 'cst-demo-005',
          firstName: 'Kavya',
          lastName: 'Reddy',
          phonePrimary: '+916543210987',
          email: 'kavya.reddy@example.com',
          preferredLanguage: 'en',
          garageProfile: GarageProfile(
            loyaltyPoints: 100,
            totalSpent: 4200,
            visitCount: 1,
            lastVisitedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          vehiclesCount: 1,
          isActive: true,
        ),
      ],
    );

/// Demo detail for offline / API-unavailable sessions.
CustomerDetail customerDetailDemoData(String uuid) {
  final customer = customersDemoData.customers.firstWhere(
    (c) => c.uuid == uuid,
    orElse: () => customersDemoData.customers.first,
  );

  final vehicles = vehiclesDemoData
      .take(2)
      .map(
        (v) => CustomerVehicleSummary(
          uuid: v.uuid,
          registrationNumber: v.registrationNumber,
          maker: v.maker,
          model: v.model,
          year: v.year,
          fuelType: v.fuelType,
          color: v.color,
          odometerReading: v.odometerReading,
        ),
      )
      .toList();

  return CustomerDetail(
    uuid: customer.uuid,
    firstName: customer.firstName,
    lastName: customer.lastName,
    phonePrimary: customer.phonePrimary,
    phoneSecondary: customer.phoneSecondary,
    email: customer.email,
    preferredLanguage: customer.preferredLanguage,
    marketingOptIn: true,
    garageProfile: customer.garageProfile,
    vehicles: vehicles,
    recentJobs: [
      RecentJobSummary(
        uuid: 'job-demo-001',
        jobNumber: 'JOB-2026-0047',
        status: 'in_progress',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      RecentJobSummary(
        uuid: 'job-demo-002',
        jobNumber: 'JOB-2026-0046',
        status: 'estimate_pending',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ],
  );
}

List<Vehicle> get vehiclesDemoData => [
      Vehicle(
        uuid: 'vhc-demo-001',
        registrationNumber: 'MH12AB1234',
        chassisNumber: 'MA3FJEB1S00123456',
        engineNumber: 'K12BN1234567',
        maker: 'Maruti Suzuki',
        model: 'Swift',
        variant: 'VXi',
        year: 2020,
        color: 'Pearl Arctic White',
        fuelType: 'petrol',
        transmission: 'manual',
        bodyType: 'hatchback',
        emissionNorms: 'BS6',
        odometerReading: 42500,
        gpsTrackingConsent: false,
        registrationDate: '2020-03-15',
        registrationValidity: '2035-03-14',
        insuranceExpiry: '2027-03-14',
        isActive: true,
        complianceAlerts: [
          const ComplianceAlert(type: 'puc', status: 'expired', expiry: '2026-03-01'),
        ],
      ),
      Vehicle(
        uuid: 'vhc-demo-002',
        registrationNumber: 'MH12CD5678',
        maker: 'Hyundai',
        model: 'Creta',
        variant: 'SX',
        year: 2022,
        color: 'Typhoon Silver',
        fuelType: 'diesel',
        transmission: 'automatic',
        bodyType: 'suv',
        emissionNorms: 'BS6',
        odometerReading: 18200,
        gpsTrackingConsent: true,
        insuranceExpiry: '2028-06-10',
        isActive: true,
        complianceAlerts: [],
      ),
    ];
