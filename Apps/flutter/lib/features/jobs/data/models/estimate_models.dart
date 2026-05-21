// Estimate models — GET/PUT /jobs/{uuid}/estimate

class EstimateLine {
  final int id;
  final String name;
  final String? description;
  final double estimatedPrice;
  final double finalPrice;
  final int? laborMinutes;
  final bool isBillable;
  final bool requiresCustomerApproval;

  const EstimateLine({
    required this.id,
    required this.name,
    this.description,
    required this.estimatedPrice,
    required this.finalPrice,
    this.laborMinutes,
    required this.isBillable,
    required this.requiresCustomerApproval,
  });

  factory EstimateLine.fromJson(Map<String, dynamic> json) {
    return EstimateLine(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble() ?? 0,
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0,
      laborMinutes: (json['labor_minutes'] as num?)?.toInt(),
      isBillable: json['is_billable'] as bool? ?? true,
      requiresCustomerApproval: json['requires_customer_approval'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'id': id,
        'estimated_price': estimatedPrice,
        'final_price': finalPrice,
        if (laborMinutes != null) 'labor_minutes': laborMinutes,
      };
}

class JobEstimate {
  final String jobUuid;
  final String jobNumber;
  final String status;
  final String approvalStatus;
  final List<EstimateLine> lines;
  final double subtotal;
  final double estimatedAmount;
  final String currency;

  const JobEstimate({
    required this.jobUuid,
    required this.jobNumber,
    required this.status,
    required this.approvalStatus,
    required this.lines,
    required this.subtotal,
    required this.estimatedAmount,
    required this.currency,
  });

  factory JobEstimate.fromJson(Map<String, dynamic> json) {
    return JobEstimate(
      jobUuid: json['job_uuid'] as String? ?? '',
      jobNumber: json['job_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      lines: (json['lines'] as List<dynamic>?)
              ?.map((e) => EstimateLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      estimatedAmount: (json['estimated_amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }
}

class InspectionCompareItem {
  final String componentKey;
  final String componentName;
  final String intakeStatus;
  final String deliveryStatus;
  final String? type;

  const InspectionCompareItem({
    required this.componentKey,
    required this.componentName,
    required this.intakeStatus,
    required this.deliveryStatus,
    this.type,
  });

  factory InspectionCompareItem.fromJson(Map<String, dynamic> json) {
    return InspectionCompareItem(
      componentKey: json['component_key'] as String? ?? '',
      componentName: json['component_name'] as String? ?? '',
      intakeStatus: json['intake_status'] as String? ?? '',
      deliveryStatus: json['delivery_status'] as String? ?? '',
      type: json['type'] as String?,
    );
  }
}

class InspectionCompareResult {
  final List<InspectionCompareItem> newDamage;

  const InspectionCompareResult({required this.newDamage});

  factory InspectionCompareResult.fromJson(Map<String, dynamic> json) {
    final items = json['new_damage'] as List<dynamic>? ?? [];
    return InspectionCompareResult(
      newDamage: items
          .map((e) => InspectionCompareItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get hasNewDamage => newDamage.isNotEmpty;
}
