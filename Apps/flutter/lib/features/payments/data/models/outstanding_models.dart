class OutstandingInvoice {
  final String uuid;
  final String invoiceNumber;
  final String status;
  final double grandTotal;
  final double amountPaid;
  final double balanceDue;
  final DateTime? issuedDate;
  final DateTime? dueDate;
  final String customerName;
  final String customerUuid;
  final String? customerPhone;
  final String vehicleRegistration;

  const OutstandingInvoice({
    required this.uuid,
    required this.invoiceNumber,
    required this.status,
    required this.grandTotal,
    required this.amountPaid,
    required this.balanceDue,
    this.issuedDate,
    this.dueDate,
    required this.customerName,
    required this.customerUuid,
    this.customerPhone,
    required this.vehicleRegistration,
  });

  factory OutstandingInvoice.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicle'] as Map<String, dynamic>? ?? {};
    return OutstandingInvoice(
      uuid: json['uuid'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      status: json['status'] as String? ?? 'sent',
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0,
      issuedDate: json['issued_date'] != null
          ? DateTime.tryParse(json['issued_date'] as String)
          : null,
      dueDate:
          json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      customerName: customer['name'] as String? ?? '—',
      customerUuid: customer['uuid'] as String? ?? '',
      customerPhone: customer['phone'] as String?,
      vehicleRegistration: vehicle['registration_number'] as String? ?? '—',
    );
  }
}

class OutstandingSummary {
  final List<OutstandingInvoice> invoices;
  final double totalOutstanding;
  final bool hasMore;
  final int currentPage;

  const OutstandingSummary({
    required this.invoices,
    required this.totalOutstanding,
    required this.hasMore,
    required this.currentPage,
  });

  factory OutstandingSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final current = (meta['current_page'] as num?)?.toInt() ?? 1;
    final last = (meta['last_page'] as num?)?.toInt() ?? 1;
    return OutstandingSummary(
      invoices: data.map((e) => OutstandingInvoice.fromJson(e as Map<String, dynamic>)).toList(),
      totalOutstanding: (meta['total_outstanding'] as num?)?.toDouble() ?? 0,
      hasMore: current < last,
      currentPage: current,
    );
  }
}
