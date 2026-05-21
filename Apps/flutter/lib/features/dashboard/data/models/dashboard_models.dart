/// Dashboard summary data model.
class DashboardSummary {
  final int jobsToday;
  final String revenueDisplay; // e.g. "₹2,84,500"
  final double revenueRaw;
  final double revenueChangePercent;
  final int pendingApprovals;
  final int lowStockItems;
  final List<RevenuePoint> weeklyRevenue;
  final List<ServiceBay> serviceBays;
  final List<ActiveJob> activeJobs;

  const DashboardSummary({
    required this.jobsToday,
    required this.revenueDisplay,
    required this.revenueRaw,
    required this.revenueChangePercent,
    required this.pendingApprovals,
    required this.lowStockItems,
    required this.weeklyRevenue,
    required this.serviceBays,
    required this.activeJobs,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? json;
    return DashboardSummary(
      jobsToday: (summary['jobs_today'] as num?)?.toInt() ?? 0,
      revenueDisplay: summary['revenue_display'] as String? ?? '₹0',
      revenueRaw: (summary['revenue_raw'] as num?)?.toDouble() ?? 0,
      revenueChangePercent: (summary['revenue_change_percent'] as num?)?.toDouble() ?? 0,
      pendingApprovals: (summary['pending_approvals'] as num?)?.toInt() ?? 0,
      lowStockItems: (summary['low_stock_items'] as num?)?.toInt() ?? 0,
      weeklyRevenue: (json['weekly_revenue'] as List<dynamic>?)
              ?.map((e) => RevenuePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      serviceBays: (json['service_bays'] as List<dynamic>?)
              ?.map((e) => ServiceBay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeJobs: (json['active_jobs'] as List<dynamic>?)
              ?.map((e) => ActiveJob.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RevenuePoint {
  final String dayLabel; // e.g. "Thu"
  final double amount;

  const RevenuePoint({required this.dayLabel, required this.amount});

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => RevenuePoint(
        dayLabel: json['day'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

enum BayStatus { occupied, available, maintenance }

class ServiceBay {
  final String name;
  final String type;
  final BayStatus status;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? jobNumber;
  final double progressPercent;

  const ServiceBay({
    required this.name,
    required this.type,
    required this.status,
    this.vehiclePlate,
    this.vehicleModel,
    this.jobNumber,
    this.progressPercent = 0,
  });

  factory ServiceBay.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'available';
    final status = statusStr == 'occupied'
        ? BayStatus.occupied
        : statusStr == 'maintenance'
            ? BayStatus.maintenance
            : BayStatus.available;

    return ServiceBay(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: status,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      jobNumber: json['job_number'] as String?,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ActiveJob {
  final String uuid; // used for navigation to /jobs/:uuid
  final String jobNumber;
  final String status;
  final String customerName;
  final String vehicleDescription;
  final String vehiclePlate;
  final String techInitials;
  final String techName;
  final String etaDisplay;
  final double progressPercent;

  const ActiveJob({
    required this.uuid,
    required this.jobNumber,
    required this.status,
    required this.customerName,
    required this.vehicleDescription,
    required this.vehiclePlate,
    required this.techInitials,
    required this.techName,
    required this.etaDisplay,
    required this.progressPercent,
  });

  factory ActiveJob.fromJson(Map<String, dynamic> json) => ActiveJob(
        uuid: json['uuid'] as String? ?? json['job_number'] as String? ?? '',
        jobNumber: json['job_number'] as String? ?? '',
        status: json['status'] as String? ?? 'in_progress',
        customerName: json['customer_name'] as String? ?? '',
        vehicleDescription: json['vehicle_description'] as String? ?? '',
        vehiclePlate: json['vehicle_plate'] as String? ?? '',
        techInitials: json['tech_initials'] as String? ?? '--',
        techName: json['tech_name'] as String? ?? 'Unassigned',
        etaDisplay: json['eta_display'] as String? ?? '—',
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
      );
}

/// Demo/fallback data used when API is unavailable.
DashboardSummary get dashboardDemoData => DashboardSummary(
      jobsToday: 12,
      revenueDisplay: '₹2,84,500',
      revenueRaw: 284500,
      revenueChangePercent: 8.2,
      pendingApprovals: 3,
      lowStockItems: 5,
      weeklyRevenue: [
        const RevenuePoint(dayLabel: 'Thu', amount: 32000),
        const RevenuePoint(dayLabel: 'Fri', amount: 38000),
        const RevenuePoint(dayLabel: 'Sat', amount: 45000),
        const RevenuePoint(dayLabel: 'Sun', amount: 18000),
        const RevenuePoint(dayLabel: 'Mon', amount: 52000),
        const RevenuePoint(dayLabel: 'Tue', amount: 61000),
        const RevenuePoint(dayLabel: 'Today', amount: 78000),
      ],
      serviceBays: [
        const ServiceBay(
          name: 'Bay A',
          type: 'Mechanical',
          status: BayStatus.occupied,
          vehiclePlate: 'MH12AB1234',
          vehicleModel: 'Maruti Swift · JOB-2847',
          progressPercent: 0.65,
        ),
        const ServiceBay(
          name: 'Bay B',
          type: 'Body Work',
          status: BayStatus.occupied,
          vehiclePlate: 'DL8CAF9876',
          vehicleModel: 'Hyundai i20 · JOB-2846',
          progressPercent: 0.20,
        ),
        const ServiceBay(name: 'Bay C', type: 'Detailing', status: BayStatus.available),
        const ServiceBay(name: 'Bay D', type: 'Tyre & Alignment', status: BayStatus.maintenance),
      ],
      activeJobs: [
        const ActiveJob(
          uuid: 'job-demo-001',
          jobNumber: 'JOB-2847',
          status: 'in_progress',
          customerName: 'Rahul Sharma',
          vehicleDescription: 'Maruti Swift VXI',
          vehiclePlate: 'MH12AB1234',
          techInitials: 'AK',
          techName: 'Amit Kamble',
          etaDisplay: 'ETA 3:30 PM',
          progressPercent: 0.65,
        ),
        const ActiveJob(
          uuid: 'job-demo-002',
          jobNumber: 'JOB-2846',
          status: 'estimate_pending',
          customerName: 'Priya Patel',
          vehicleDescription: 'Hyundai i20 Asta',
          vehiclePlate: 'DL8CAF9876',
          techInitials: 'SM',
          techName: 'Suresh More',
          etaDisplay: 'Tomorrow',
          progressPercent: 0.18,
        ),
        const ActiveJob(
          uuid: 'job-demo-003',
          jobNumber: 'JOB-2845',
          status: 'qc_pending',
          customerName: 'Kavya Reddy',
          vehicleDescription: 'Honda City ZX',
          vehiclePlate: 'KA01MX5678',
          techInitials: 'RP',
          techName: 'Rajan Patil',
          etaDisplay: 'ETA 5:00 PM',
          progressPercent: 0.88,
        ),
        const ActiveJob(
          uuid: 'job-demo-004',
          jobNumber: 'JOB-2844',
          status: 'ready_for_delivery',
          customerName: 'Sunita Gupta',
          vehicleDescription: 'Toyota Innova Crysta',
          vehiclePlate: 'TN09BD3210',
          techInitials: 'AK',
          techName: 'Amit Kamble',
          etaDisplay: 'Ready now',
          progressPercent: 1.0,
        ),
        const ActiveJob(
          uuid: 'job-demo-005',
          jobNumber: 'JOB-2843',
          status: 'in_progress',
          customerName: 'Vikram Mehta',
          vehicleDescription: 'Mahindra Thar LX',
          vehiclePlate: 'MH01ZP4567',
          techInitials: 'DS',
          techName: 'Deepak Shinde',
          etaDisplay: 'ETA 6:30 PM',
          progressPercent: 0.42,
        ),
      ],
    );
