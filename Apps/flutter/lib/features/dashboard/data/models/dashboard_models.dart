import 'package:intl/intl.dart';

/// Dashboard summary data model — maps GET /dashboard/summary envelope.
class DashboardSummary {
  final int jobsToday;
  final String revenueDisplay;
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

  static String _formatInr(double amount) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return fmt.format(amount);
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final kpis = data['kpis'] as Map<String, dynamic>? ?? {};
    final revenue = (kpis['revenue'] as num?)?.toDouble() ?? 0;
    final jobsToday = (kpis['jobs_today'] as num?)?.toInt() ?? 0;
    final activeJobsList = data['active_jobs'] as List<dynamic>? ?? [];

    final pendingApprovals = activeJobsList
        .where((j) => (j as Map<String, dynamic>)['status'] == 'estimate_pending')
        .length;

    return DashboardSummary(
      jobsToday: jobsToday,
      revenueDisplay: _formatInr(revenue),
      revenueRaw: revenue,
      revenueChangePercent: 0,
      pendingApprovals: pendingApprovals,
      lowStockItems: 0,
      weeklyRevenue: (data['revenue_chart'] as List<dynamic>?)
              ?.map((e) => RevenuePoint.fromChartJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      serviceBays: (data['service_bays'] as List<dynamic>?)
              ?.map((e) => ServiceBay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeJobs: activeJobsList
          .map((e) => ActiveJob.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RevenuePoint {
  final String dayLabel;
  final double amount;

  const RevenuePoint({required this.dayLabel, required this.amount});

  factory RevenuePoint.fromJson(Map<String, dynamic> json) => RevenuePoint(
        dayLabel: json['day'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );

  factory RevenuePoint.fromChartJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final label = date != null ? DateFormat('EEE').format(date) : dateStr;
    return RevenuePoint(
      dayLabel: label,
      amount: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
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

    final job = json['job'] as Map<String, dynamic>?;
    final vehicleDisplay = job?['vehicle'] as String?;

    return ServiceBay(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? json['bay_type'] as String? ?? '',
      status: status,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleModel: vehicleDisplay ?? json['vehicle_model'] as String?,
      jobNumber: job?['job_number'] as String? ?? json['job_number'] as String?,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ActiveJob {
  final String uuid;
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

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, name.length.clamp(1, 2)).toUpperCase() : '--';
  }

  factory ActiveJob.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final techName =
        json['technician'] as String? ?? json['tech_name'] as String? ?? 'Unassigned';

    return ActiveJob(
      uuid: json['uuid'] as String? ?? json['job_number'] as String? ?? '',
      jobNumber: json['job_number'] as String? ?? '',
      status: json['status'] as String? ?? 'in_progress',
      customerName: customer?['name'] as String? ?? json['customer_name'] as String? ?? '',
      vehicleDescription:
          vehicle?['display'] as String? ?? json['vehicle_description'] as String? ?? '',
      vehiclePlate:
          vehicle?['registration_number'] as String? ?? json['vehicle_plate'] as String? ?? '',
      techInitials: json['tech_initials'] as String? ?? _initialsFromName(techName),
      techName: techName,
      etaDisplay: json['eta_display'] as String? ?? '—',
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0,
    );
  }
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
      ],
    );
