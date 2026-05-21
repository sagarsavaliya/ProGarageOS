// Job data models — aligned with GET /jobs and GET /jobs/{uuid} API contract.

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum JobStatus {
  draft,
  intakeInspection,
  estimatePending,
  estimateApproved,
  estimateRejected,
  inProgress,
  qcPending,
  readyForDelivery,
  delivered,
  cancelled,
  onHold,
}

extension JobStatusExt on JobStatus {
  static JobStatus fromString(String s) {
    switch (s) {
      case 'draft':
        return JobStatus.draft;
      case 'intake_inspection':
      case 'inspecting':
      case 'checked_in':
        return JobStatus.intakeInspection;
      case 'estimate_pending':
        return JobStatus.estimatePending;
      case 'estimate_approved':
        return JobStatus.estimateApproved;
      case 'estimate_rejected':
        return JobStatus.estimateRejected;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'qc_pending':
      case 'quality_check':
        return JobStatus.qcPending;
      case 'ready_for_delivery':
        return JobStatus.readyForDelivery;
      case 'delivered':
        return JobStatus.delivered;
      case 'cancelled':
        return JobStatus.cancelled;
      case 'on_hold':
        return JobStatus.onHold;
      default:
        return JobStatus.inProgress;
    }
  }

  String get label {
    switch (this) {
      case JobStatus.draft:
        return 'Draft';
      case JobStatus.intakeInspection:
        return 'Intake';
      case JobStatus.estimatePending:
        return 'Estimate Pending';
      case JobStatus.estimateApproved:
        return 'Estimate Approved';
      case JobStatus.estimateRejected:
        return 'Estimate Rejected';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.qcPending:
        return 'QC Pending';
      case JobStatus.readyForDelivery:
        return 'Ready';
      case JobStatus.delivered:
        return 'Delivered';
      case JobStatus.cancelled:
        return 'Cancelled';
      case JobStatus.onHold:
        return 'On Hold';
    }
  }

  /// Short label used in filter tabs.
  String get tabLabel {
    switch (this) {
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.estimatePending:
        return 'Estimate';
      case JobStatus.qcPending:
        return 'QC';
      case JobStatus.readyForDelivery:
        return 'Ready';
      default:
        return label;
    }
  }

  String get apiValue {
    switch (this) {
      case JobStatus.draft:
        return 'draft';
      case JobStatus.intakeInspection:
        return 'inspecting';
      case JobStatus.estimatePending:
        return 'estimate_pending';
      case JobStatus.estimateApproved:
        return 'estimate_approved';
      case JobStatus.estimateRejected:
        return 'estimate_rejected';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.qcPending:
        return 'quality_check';
      case JobStatus.readyForDelivery:
        return 'ready_for_delivery';
      case JobStatus.delivered:
        return 'delivered';
      case JobStatus.cancelled:
        return 'cancelled';
      case JobStatus.onHold:
        return 'on_hold';
    }
  }
}

enum JobPriority { normal, urgent, vip }

extension JobPriorityExt on JobPriority {
  static JobPriority fromString(String s) {
    switch (s) {
      case 'urgent':
        return JobPriority.urgent;
      case 'vip':
        return JobPriority.vip;
      default:
        return JobPriority.normal;
    }
  }

  String get label {
    switch (this) {
      case JobPriority.normal:
        return 'Normal';
      case JobPriority.urgent:
        return 'Urgent';
      case JobPriority.vip:
        return 'VIP';
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-models (list & detail shared)
// ---------------------------------------------------------------------------

class JobCustomer {
  final String uuid;
  final String name;
  final String phone;
  final int loyaltyPoints;

  const JobCustomer({
    required this.uuid,
    required this.name,
    required this.phone,
    this.loyaltyPoints = 0,
  });

  factory JobCustomer.fromJson(Map<String, dynamic> json) => JobCustomer(
        uuid: json['uuid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        loyaltyPoints: (json['loyalty_points'] as num?)?.toInt() ?? 0,
      );
}

class JobVehicle {
  final String uuid;
  final String registrationNumber;
  final String makeModel;
  final String fuelType;
  final int? odometerAtIntake;
  final List<String> complianceAlerts;

  const JobVehicle({
    required this.uuid,
    required this.registrationNumber,
    required this.makeModel,
    required this.fuelType,
    this.odometerAtIntake,
    this.complianceAlerts = const [],
  });

  factory JobVehicle.fromJson(Map<String, dynamic> json) => JobVehicle(
        uuid: json['uuid'] as String? ?? '',
        registrationNumber: json['registration_number'] as String? ?? '',
        makeModel: json['make_model'] as String? ?? '',
        fuelType: json['fuel_type'] as String? ?? '',
        odometerAtIntake: (json['odometer_at_intake'] as num?)?.toInt(),
        complianceAlerts: (json['compliance_alerts'] as List<dynamic>?)
                ?.map((e) => (e as Map<String, dynamic>)['type'] as String? ?? '')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [],
      );
}

class JobTechnician {
  final String uuid;
  final String name;

  const JobTechnician({required this.uuid, required this.name});

  factory JobTechnician.fromJson(Map<String, dynamic> json) => JobTechnician(
        uuid: json['uuid'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }
}

class JobServiceBay {
  final String uuid;
  final String name;

  const JobServiceBay({required this.uuid, required this.name});

  factory JobServiceBay.fromJson(Map<String, dynamic> json) => JobServiceBay(
        uuid: json['uuid'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class TasksSummary {
  final int total;
  final int completed;
  final int inProgress;
  final int pending;

  const TasksSummary({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  factory TasksSummary.fromJson(Map<String, dynamic> json) => TasksSummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
      );

  double get progressPercent => total == 0 ? 0 : completed / total;
}

// ---------------------------------------------------------------------------
// Job (list item)
// ---------------------------------------------------------------------------

class Job {
  final String uuid;
  final String jobNumber;
  final JobStatus status;
  final JobPriority priority;
  final JobCustomer customer;
  final JobVehicle vehicle;
  final JobTechnician? primaryTechnician;
  final JobServiceBay? serviceBay;
  final List<String> serviceCategories;
  final double estimatedAmount;
  final String approvalStatus;
  final DateTime? scheduledStartAt;
  final DateTime? estimatedCompletionAt;
  final TasksSummary tasksSummary;

  const Job({
    required this.uuid,
    required this.jobNumber,
    required this.status,
    required this.priority,
    required this.customer,
    required this.vehicle,
    this.primaryTechnician,
    this.serviceBay,
    required this.serviceCategories,
    required this.estimatedAmount,
    required this.approvalStatus,
    this.scheduledStartAt,
    this.estimatedCompletionAt,
    required this.tasksSummary,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        uuid: json['uuid'] as String? ?? '',
        jobNumber: json['job_number'] as String? ?? '',
        status: JobStatusExt.fromString(json['status'] as String? ?? ''),
        priority: JobPriorityExt.fromString(json['priority'] as String? ?? ''),
        customer: JobCustomer.fromJson(json['customer'] as Map<String, dynamic>? ?? {}),
        vehicle: JobVehicle.fromJson(json['vehicle'] as Map<String, dynamic>? ?? {}),
        primaryTechnician: json['primary_technician'] != null
            ? JobTechnician.fromJson(json['primary_technician'] as Map<String, dynamic>)
            : null,
        serviceBay: json['service_bay'] != null
            ? JobServiceBay.fromJson(json['service_bay'] as Map<String, dynamic>)
            : null,
        serviceCategories: (json['service_categories'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        estimatedAmount: (json['estimated_amount'] as num?)?.toDouble() ?? 0,
        approvalStatus: json['approval_status'] as String? ?? 'pending',
        scheduledStartAt: json['scheduled_start_at'] != null
            ? DateTime.tryParse(json['scheduled_start_at'] as String)
            : null,
        estimatedCompletionAt: json['estimated_completion_at'] != null
            ? DateTime.tryParse(json['estimated_completion_at'] as String)
            : null,
        tasksSummary:
            TasksSummary.fromJson(json['tasks_summary'] as Map<String, dynamic>? ?? {}),
      );
}

// ---------------------------------------------------------------------------
// Task item (detail only)
// ---------------------------------------------------------------------------

class TaskItem {
  final int? id;
  final String uuid;
  final String name;
  final String source; // 'planned' | 'discovered'
  final String status; // API: pending_approval, approved, in_progress, completed, ...
  final JobTechnician? assignedTechnician;
  final double estimatedPrice;
  final double? finalPrice;
  final int? laborMinutes;
  final bool isBillable;
  final bool requiresCustomerApproval;

  const TaskItem({
    this.id,
    required this.uuid,
    required this.name,
    required this.source,
    required this.status,
    this.assignedTechnician,
    required this.estimatedPrice,
    this.finalPrice,
    this.laborMinutes,
    required this.isBillable,
    required this.requiresCustomerApproval,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    final techRaw = json['technician'] ?? json['assigned_technician'];
    JobTechnician? technician;
    if (techRaw is Map<String, dynamic>) {
      technician = JobTechnician.fromJson(techRaw);
    }

    return TaskItem(
      id: id,
      uuid: json['uuid'] as String? ?? (id != null ? id.toString() : ''),
      name: json['name'] as String? ?? '',
      source: json['source'] as String? ?? 'planned',
      status: json['status'] as String? ?? 'pending',
      assignedTechnician: technician,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0,
      finalPrice: (json['final_price'] as num?)?.toDouble(),
      laborMinutes: (json['labor_minutes'] as num?)?.toInt(),
      isBillable: json['is_billable'] as bool? ?? true,
      requiresCustomerApproval: json['requires_customer_approval'] as bool? ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Job Detail (full — GET /jobs/{uuid})
// ---------------------------------------------------------------------------

class JobDetail {
  final String uuid;
  final String jobNumber;
  final JobStatus status;
  final JobPriority priority;
  final JobCustomer customer;
  final JobVehicle vehicle;
  final JobTechnician? primaryTechnician;
  final JobServiceBay? serviceBay;
  final String? customerComplaint;
  final List<Map<String, dynamic>> serviceCategories;
  final List<TaskItem> tasks;
  final Map<String, dynamic> inspectionSummary;
  final bool deliveryInspectionCompleted;
  final Map<String, dynamic> estimateSummary;
  final Map<String, dynamic> billingSummary;
  final Map<String, dynamic> timeline;

  const JobDetail({
    required this.uuid,
    required this.jobNumber,
    required this.status,
    required this.priority,
    required this.customer,
    required this.vehicle,
    this.primaryTechnician,
    this.serviceBay,
    this.customerComplaint,
    required this.serviceCategories,
    required this.tasks,
    required this.inspectionSummary,
    this.deliveryInspectionCompleted = false,
    this.estimateSummary = const {},
    required this.billingSummary,
    required this.timeline,
  });

  factory JobDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final techRaw = data['primary_technician'] ?? data['technician'];
    final bayRaw = data['service_bay'] ?? data['bay'];
    final timeline = Map<String, dynamic>.from(data['timeline'] as Map<String, dynamic>? ?? {});
    if (data['scheduled_start_at'] != null) {
      timeline['scheduled_start_at'] = data['scheduled_start_at'];
    }
    if (data['actual_start_at'] != null) {
      timeline['actual_start_at'] = data['actual_start_at'];
    }
    if (data['eta'] != null) {
      timeline['estimated_completion_at'] = data['eta'];
    }

    return JobDetail(
      uuid: data['uuid'] as String? ?? '',
      jobNumber: data['job_number'] as String? ?? '',
      status: JobStatusExt.fromString(data['status'] as String? ?? ''),
      priority: JobPriorityExt.fromString(data['priority'] as String? ?? ''),
      customer: JobCustomer.fromJson(data['customer'] as Map<String, dynamic>? ?? {}),
      vehicle: JobVehicle.fromJson(data['vehicle'] as Map<String, dynamic>? ?? {}),
      primaryTechnician: techRaw is Map<String, dynamic>
          ? JobTechnician.fromJson(techRaw)
          : null,
      serviceBay: bayRaw is Map<String, dynamic> ? JobServiceBay.fromJson(bayRaw) : null,
      customerComplaint: data['customer_complaint'] as String?,
      serviceCategories:
          (data['service_categories'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      tasks: (data['tasks'] as List<dynamic>?)
              ?.map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inspectionSummary: data['inspection_summary'] as Map<String, dynamic>? ?? {},
      deliveryInspectionCompleted: data['delivery_inspection_completed'] as bool? ?? false,
      estimateSummary: data['estimate'] as Map<String, dynamic>? ?? {},
      billingSummary: data['billing_summary'] as Map<String, dynamic>? ??
          (data['invoice'] is Map<String, dynamic>
              ? {'invoice_uuid': (data['invoice'] as Map<String, dynamic>)['uuid']}
              : {}),
      timeline: timeline,
    );
  }
}

// ---------------------------------------------------------------------------
// Paginated response wrapper
// ---------------------------------------------------------------------------

class PaginatedJobs {
  final List<Job> jobs;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedJobs({
    required this.jobs,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedJobs.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedJobs(
      jobs: (json['data'] as List<dynamic>?)
              ?.map((e) => Job.fromJson(e as Map<String, dynamic>))
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

PaginatedJobs get jobsDemoData => PaginatedJobs(
      currentPage: 1,
      lastPage: 2,
      total: 12,
      jobs: [
        Job(
          uuid: 'job-demo-001',
          jobNumber: 'JOB-2026-0047',
          status: JobStatus.inProgress,
          priority: JobPriority.urgent,
          customer: const JobCustomer(uuid: 'c1', name: 'Rahul Sharma', phone: '+919876543210'),
          vehicle: const JobVehicle(
            uuid: 'v1',
            registrationNumber: 'MH12AB1234',
            makeModel: 'Maruti Swift VXI 2020',
            fuelType: 'petrol',
          ),
          primaryTechnician: const JobTechnician(uuid: 't1', name: 'Amit Kamble'),
          serviceBay: const JobServiceBay(uuid: 'b1', name: 'Bay A — General Lift'),
          serviceCategories: const ['General Service', 'AC Service'],
          estimatedAmount: 4850,
          approvalStatus: 'approved',
          scheduledStartAt: DateTime.now().subtract(const Duration(hours: 2)),
          estimatedCompletionAt: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
          tasksSummary: const TasksSummary(total: 5, completed: 2, inProgress: 1, pending: 2),
        ),
        Job(
          uuid: 'job-demo-002',
          jobNumber: 'JOB-2026-0046',
          status: JobStatus.estimatePending,
          priority: JobPriority.normal,
          customer: const JobCustomer(uuid: 'c2', name: 'Priya Patel', phone: '+919765432109'),
          vehicle: const JobVehicle(
            uuid: 'v2',
            registrationNumber: 'DL8CAF9876',
            makeModel: 'Hyundai i20 Asta 2021',
            fuelType: 'petrol',
          ),
          primaryTechnician: const JobTechnician(uuid: 't2', name: 'Suresh More'),
          serviceCategories: const ['Denting & Painting'],
          estimatedAmount: 12500,
          approvalStatus: 'pending',
          tasksSummary: const TasksSummary(total: 3, completed: 0, inProgress: 0, pending: 3),
        ),
        Job(
          uuid: 'job-demo-003',
          jobNumber: 'JOB-2026-0045',
          status: JobStatus.qcPending,
          priority: JobPriority.normal,
          customer: const JobCustomer(uuid: 'c3', name: 'Kavya Reddy', phone: '+918765432109'),
          vehicle: const JobVehicle(
            uuid: 'v3',
            registrationNumber: 'KA01MX5678',
            makeModel: 'Honda City ZX 2022',
            fuelType: 'petrol',
          ),
          primaryTechnician: const JobTechnician(uuid: 't3', name: 'Rajan Patil'),
          serviceBay: const JobServiceBay(uuid: 'b2', name: 'Bay B — Alignment'),
          serviceCategories: const ['Wheel Balancing & Alignment'],
          estimatedAmount: 1800,
          approvalStatus: 'approved',
          estimatedCompletionAt: DateTime.now().add(const Duration(hours: 2)),
          tasksSummary: const TasksSummary(total: 4, completed: 4, inProgress: 0, pending: 0),
        ),
        Job(
          uuid: 'job-demo-004',
          jobNumber: 'JOB-2026-0044',
          status: JobStatus.readyForDelivery,
          priority: JobPriority.vip,
          customer: const JobCustomer(uuid: 'c4', name: 'Sunita Gupta', phone: '+917654321098'),
          vehicle: const JobVehicle(
            uuid: 'v4',
            registrationNumber: 'TN09BD3210',
            makeModel: 'Toyota Innova Crysta 2019',
            fuelType: 'diesel',
          ),
          primaryTechnician: const JobTechnician(uuid: 't1', name: 'Amit Kamble'),
          serviceCategories: const ['General Service', 'Brake Service'],
          estimatedAmount: 8200,
          approvalStatus: 'approved',
          tasksSummary: const TasksSummary(total: 6, completed: 6, inProgress: 0, pending: 0),
        ),
        Job(
          uuid: 'job-demo-005',
          jobNumber: 'JOB-2026-0043',
          status: JobStatus.inProgress,
          priority: JobPriority.normal,
          customer: const JobCustomer(uuid: 'c5', name: 'Vikram Mehta', phone: '+916543210987'),
          vehicle: const JobVehicle(
            uuid: 'v5',
            registrationNumber: 'MH01ZP4567',
            makeModel: 'Mahindra Thar LX 2023',
            fuelType: 'diesel',
          ),
          primaryTechnician: const JobTechnician(uuid: 't4', name: 'Deepak Shinde'),
          serviceBay: const JobServiceBay(uuid: 'b3', name: 'Bay C — Wash'),
          serviceCategories: const ['General Service'],
          estimatedAmount: 3500,
          approvalStatus: 'approved',
          tasksSummary: const TasksSummary(total: 4, completed: 2, inProgress: 1, pending: 1),
        ),
      ],
    );

/// Demo detail for offline / API-unavailable sessions.
JobDetail jobDetailDemoData(String uuid) {
  final job = jobsDemoData.jobs.firstWhere(
    (j) => j.uuid == uuid,
    orElse: () => jobsDemoData.jobs.first,
  );

  return JobDetail(
    uuid: job.uuid,
    jobNumber: job.jobNumber,
    status: job.status,
    priority: job.priority,
    customer: job.customer,
    vehicle: job.vehicle,
    primaryTechnician: job.primaryTechnician,
    serviceBay: job.serviceBay,
    serviceCategories: job.serviceCategories.map((c) => {'name': c}).toList(),
    tasks: [
      TaskItem(
        id: 1,
        uuid: 'task-demo-1',
        name: 'Engine oil change',
        source: 'planned',
        status: 'completed',
        assignedTechnician: job.primaryTechnician,
        estimatedPrice: 800,
        finalPrice: 800,
        laborMinutes: 45,
        isBillable: true,
        requiresCustomerApproval: false,
      ),
      TaskItem(
        id: 2,
        uuid: 'task-demo-2',
        name: 'Brake pad inspection',
        source: 'planned',
        status: job.status == JobStatus.inProgress ? 'in_progress' : 'pending',
        assignedTechnician: job.primaryTechnician,
        estimatedPrice: 450,
        laborMinutes: 30,
        isBillable: true,
        requiresCustomerApproval: false,
      ),
      TaskItem(
        id: 3,
        uuid: 'task-demo-3',
        name: 'AC gas top-up',
        source: 'discovered',
        status: 'pending_approval',
        estimatedPrice: 1200,
        isBillable: true,
        requiresCustomerApproval: true,
      ),
    ],
    inspectionSummary: const {
      'status': 'completed',
      'items_checked': 12,
      'issues_found': 1,
    },
    billingSummary: {
      'estimated_amount': job.estimatedAmount,
      'approved_amount': job.estimatedAmount,
      'currency': 'INR',
    },
    timeline: {
      'intake_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      'started_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
  );
}
