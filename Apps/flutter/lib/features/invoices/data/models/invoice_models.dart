// Invoice data models — aligned with GET /api/invoices and GET /api/invoices/{uuid}.

// ---------------------------------------------------------------------------
// Sub-models
// ---------------------------------------------------------------------------

class InvoiceJob {
  final String uuid;
  final String jobNumber;

  const InvoiceJob({required this.uuid, required this.jobNumber});

  factory InvoiceJob.fromJson(Map<String, dynamic> json) => InvoiceJob(
        uuid: json['uuid'] as String? ?? '',
        jobNumber: json['job_number'] as String? ?? '',
      );
}

class InvoiceCustomer {
  final String uuid;
  final String fullName;
  final String phone;
  final String? email;

  const InvoiceCustomer({
    required this.uuid,
    required this.fullName,
    required this.phone,
    this.email,
  });

  factory InvoiceCustomer.fromJson(Map<String, dynamic> json) => InvoiceCustomer(
        uuid: json['uuid'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String?,
      );
}

class InvoiceVehicle {
  final String make;
  final String model;
  final String registrationNumber;
  final int? year;

  const InvoiceVehicle({
    required this.make,
    required this.model,
    required this.registrationNumber,
    this.year,
  });

  String get makeModel => '$make $model';

  factory InvoiceVehicle.fromJson(Map<String, dynamic> json) => InvoiceVehicle(
        make: json['make'] as String? ?? '',
        model: json['model'] as String? ?? '',
        registrationNumber: json['registration_number'] as String? ?? '',
        year: (json['year'] as num?)?.toInt(),
      );
}

class InvoicePaymentMethod {
  final String name;
  final String iconKey;

  const InvoicePaymentMethod({required this.name, required this.iconKey});

  factory InvoicePaymentMethod.fromJson(Map<String, dynamic> json) => InvoicePaymentMethod(
        name: json['name'] as String? ?? '',
        iconKey: json['icon_key'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// InvoiceItem — single line item
// ---------------------------------------------------------------------------

class InvoiceItem {
  final String uuid;
  final String lineType; // service|part|labour|discount|tax|fee|adjustment
  final String description;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double lineTotal;
  final int sortOrder;

  const InvoiceItem({
    required this.uuid,
    required this.lineType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.taxAmount,
    required this.lineTotal,
    required this.sortOrder,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        uuid: json['uuid'] as String? ?? '',
        lineType: json['line_type'] as String? ?? 'service',
        description: json['description'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
        unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
        taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0,
        taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
        lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}

// ---------------------------------------------------------------------------
// PaymentRecord — recorded payment
// ---------------------------------------------------------------------------

class PaymentRecord {
  final String uuid;
  final double amount;
  final InvoicePaymentMethod paymentMethod;
  final String? referenceNumber;
  final DateTime paidAt;
  final String? notes;

  const PaymentRecord({
    required this.uuid,
    required this.amount,
    required this.paymentMethod,
    this.referenceNumber,
    required this.paidAt,
    this.notes,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
        uuid: json['uuid'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paymentMethod: InvoicePaymentMethod.fromJson(
          json['payment_method'] as Map<String, dynamic>? ?? {},
        ),
        referenceNumber: json['reference_number'] as String?,
        paidAt: DateTime.tryParse(json['paid_at'] as String? ?? '') ?? DateTime.now(),
        notes: json['notes'] as String?,
      );
}

// ---------------------------------------------------------------------------
// PaymentMethod — available payment methods
// ---------------------------------------------------------------------------

class PaymentMethod {
  final int id;
  final String name;
  final String iconKey;

  const PaymentMethod({required this.id, required this.name, required this.iconKey});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] as String? ?? '').toUpperCase();
    return PaymentMethod(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      iconKey: json['icon_key'] as String? ?? _iconKeyForCode(code),
    );
  }

  static String _iconKeyForCode(String code) {
    switch (code) {
      case 'CASH':
        return 'cash';
      case 'UPI':
        return 'upi';
      case 'CARD':
        return 'card';
      case 'CHEQUE':
        return 'cheque';
      case 'INSURANCE':
        return 'insurance';
      default:
        return 'payment';
    }
  }
}

// ---------------------------------------------------------------------------
// RecordPaymentRequest
// ---------------------------------------------------------------------------

class RecordPaymentRequest {
  final double amount;
  final int paymentMethodId;
  final String? referenceNumber;
  final String? notes;

  const RecordPaymentRequest({
    required this.amount,
    required this.paymentMethodId,
    this.referenceNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'payment_method_id': paymentMethodId,
        if (referenceNumber != null && referenceNumber!.isNotEmpty)
          'reference_number': referenceNumber,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

// ---------------------------------------------------------------------------
// InvoiceListItem — for list screen
// ---------------------------------------------------------------------------

class InvoiceListItem {
  final String uuid;
  final String invoiceNumber;
  final String status;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final DateTime issuedDate;
  final DateTime? dueDate;
  final InvoiceJob serviceJob;
  final InvoiceCustomer customer;
  final InvoiceVehicle vehicle;

  const InvoiceListItem({
    required this.uuid,
    required this.invoiceNumber,
    required this.status,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDue,
    required this.issuedDate,
    this.dueDate,
    required this.serviceJob,
    required this.customer,
    required this.vehicle,
  });

  bool get isOverdue {
    if (status == 'paid') return false;
    return dueDate != null && dueDate!.isBefore(DateTime.now());
  }

  factory InvoiceListItem.fromJson(Map<String, dynamic> json) => InvoiceListItem(
        uuid: json['uuid'] as String? ?? '',
        invoiceNumber: json['invoice_number'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
        balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0,
        issuedDate: DateTime.tryParse(json['issued_date'] as String? ?? '') ?? DateTime.now(),
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date'] as String)
            : null,
        serviceJob: InvoiceJob.fromJson(json['service_job'] as Map<String, dynamic>? ?? {}),
        customer: InvoiceCustomer.fromJson(json['customer'] as Map<String, dynamic>? ?? {}),
        vehicle: InvoiceVehicle.fromJson(json['vehicle'] as Map<String, dynamic>? ?? {}),
      );
}

// ---------------------------------------------------------------------------
// InvoiceDetail — full detail (GET /api/invoices/{uuid})
// ---------------------------------------------------------------------------

class InvoiceDetail {
  final String uuid;
  final String invoiceNumber;
  final String status;
  final DateTime issuedDate;
  final DateTime? dueDate;
  final String? notes;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;
  final InvoiceJob serviceJob;
  final InvoiceCustomer customer;
  final InvoiceVehicle vehicle;
  final List<InvoiceItem> items;
  final List<PaymentRecord> payments;

  const InvoiceDetail({
    required this.uuid,
    required this.invoiceNumber,
    required this.status,
    required this.issuedDate,
    this.dueDate,
    this.notes,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceDue,
    required this.serviceJob,
    required this.customer,
    required this.vehicle,
    required this.items,
    required this.payments,
  });

  bool get isOverdue {
    if (status == 'paid') return false;
    return dueDate != null && dueDate!.isBefore(DateTime.now());
  }

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return InvoiceDetail(
      uuid: data['uuid'] as String? ?? '',
      invoiceNumber: data['invoice_number'] as String? ?? '',
      status: data['status'] as String? ?? 'draft',
      issuedDate: DateTime.tryParse(data['issued_date'] as String? ?? '') ?? DateTime.now(),
      dueDate: data['due_date'] != null
          ? DateTime.tryParse(data['due_date'] as String)
          : null,
      notes: data['notes'] as String?,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (data['tax_amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (data['discount_amount'] as num?)?.toDouble() ?? 0,
      totalAmount: (data['total_amount'] as num?)?.toDouble() ?? 0,
      paidAmount: (data['paid_amount'] as num?)?.toDouble() ?? 0,
      balanceDue: (data['balance_due'] as num?)?.toDouble() ?? 0,
      serviceJob: InvoiceJob.fromJson(data['service_job'] as Map<String, dynamic>? ?? {}),
      customer: InvoiceCustomer.fromJson(data['customer'] as Map<String, dynamic>? ?? {}),
      vehicle: InvoiceVehicle.fromJson(data['vehicle'] as Map<String, dynamic>? ?? {}),
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      payments: (data['payments'] as List<dynamic>?)
              ?.map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// ---------------------------------------------------------------------------
// PaginatedInvoices
// ---------------------------------------------------------------------------

class PaginatedInvoices {
  final List<InvoiceListItem> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedInvoices({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedInvoices.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedInvoices(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => InvoiceListItem.fromJson(e as Map<String, dynamic>))
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

final _now = DateTime.now();

PaginatedInvoices get invoicesDemoData => PaginatedInvoices(
      currentPage: 1,
      lastPage: 1,
      total: 5,
      data: [
        InvoiceListItem(
          uuid: 'inv-demo-001',
          invoiceNumber: 'INV-2026-0047',
          status: 'paid',
          totalAmount: 4850.00,
          paidAmount: 4850.00,
          balanceDue: 0.00,
          issuedDate: _now.subtract(const Duration(days: 3)),
          dueDate: _now.subtract(const Duration(days: 3)),
          serviceJob: const InvoiceJob(uuid: 'job-demo-001', jobNumber: 'JOB-2026-0047'),
          customer: const InvoiceCustomer(
            uuid: 'c1',
            fullName: 'Rahul Sharma',
            phone: '+919876543210',
            email: 'rahul.sharma@gmail.com',
          ),
          vehicle: const InvoiceVehicle(
            make: 'Maruti',
            model: 'Swift VXI',
            registrationNumber: 'MH12AB1234',
            year: 2020,
          ),
        ),
        InvoiceListItem(
          uuid: 'inv-demo-002',
          invoiceNumber: 'INV-2026-0046',
          status: 'sent',
          totalAmount: 12500.00,
          paidAmount: 0.00,
          balanceDue: 12500.00,
          issuedDate: _now.subtract(const Duration(days: 5)),
          dueDate: _now.add(const Duration(days: 2)),
          serviceJob: const InvoiceJob(uuid: 'job-demo-002', jobNumber: 'JOB-2026-0046'),
          customer: const InvoiceCustomer(
            uuid: 'c2',
            fullName: 'Priya Patel',
            phone: '+919765432109',
            email: 'priya.patel@outlook.com',
          ),
          vehicle: const InvoiceVehicle(
            make: 'Hyundai',
            model: 'i20 Asta',
            registrationNumber: 'DL8CAF9876',
            year: 2021,
          ),
        ),
        InvoiceListItem(
          uuid: 'inv-demo-003',
          invoiceNumber: 'INV-2026-0045',
          status: 'overdue',
          totalAmount: 1800.00,
          paidAmount: 0.00,
          balanceDue: 1800.00,
          issuedDate: _now.subtract(const Duration(days: 12)),
          dueDate: _now.subtract(const Duration(days: 5)),
          serviceJob: const InvoiceJob(uuid: 'job-demo-003', jobNumber: 'JOB-2026-0045'),
          customer: const InvoiceCustomer(
            uuid: 'c3',
            fullName: 'Kavya Reddy',
            phone: '+918765432109',
            email: 'kavya.reddy@gmail.com',
          ),
          vehicle: const InvoiceVehicle(
            make: 'Honda',
            model: 'City ZX',
            registrationNumber: 'KA01MX5678',
            year: 2022,
          ),
        ),
        InvoiceListItem(
          uuid: 'inv-demo-004',
          invoiceNumber: 'INV-2026-0044',
          status: 'partially_paid',
          totalAmount: 8200.00,
          paidAmount: 4000.00,
          balanceDue: 4200.00,
          issuedDate: _now.subtract(const Duration(days: 2)),
          dueDate: _now.add(const Duration(days: 5)),
          serviceJob: const InvoiceJob(uuid: 'job-demo-004', jobNumber: 'JOB-2026-0044'),
          customer: const InvoiceCustomer(
            uuid: 'c4',
            fullName: 'Sunita Gupta',
            phone: '+917654321098',
            email: 'sunita.gupta@yahoo.com',
          ),
          vehicle: const InvoiceVehicle(
            make: 'Toyota',
            model: 'Innova Crysta',
            registrationNumber: 'TN09BD3210',
            year: 2019,
          ),
        ),
        InvoiceListItem(
          uuid: 'inv-demo-005',
          invoiceNumber: 'INV-2026-0043',
          status: 'draft',
          totalAmount: 3500.00,
          paidAmount: 0.00,
          balanceDue: 3500.00,
          issuedDate: _now.subtract(const Duration(days: 1)),
          dueDate: _now.add(const Duration(days: 6)),
          serviceJob: const InvoiceJob(uuid: 'job-demo-005', jobNumber: 'JOB-2026-0043'),
          customer: const InvoiceCustomer(
            uuid: 'c5',
            fullName: 'Vikram Mehta',
            phone: '+916543210987',
            email: 'vikram.mehta@gmail.com',
          ),
          vehicle: const InvoiceVehicle(
            make: 'Mahindra',
            model: 'Thar LX',
            registrationNumber: 'MH01ZP4567',
            year: 2023,
          ),
        ),
      ],
    );

/// Full detail demo data (used as fallback in invoice detail screen).
InvoiceDetail invoiceDetailDemoData(String uuid) {
  switch (uuid) {
    case 'inv-demo-001':
      return InvoiceDetail(
        uuid: 'inv-demo-001',
        invoiceNumber: 'INV-2026-0047',
        status: 'paid',
        issuedDate: _now.subtract(const Duration(days: 3)),
        dueDate: _now.subtract(const Duration(days: 3)),
        notes: 'Customer requested express service. Vehicle ready ahead of schedule.',
        subtotal: 4110.00,
        taxAmount: 739.80,
        discountAmount: 0.00,
        totalAmount: 4849.80,
        paidAmount: 4849.80,
        balanceDue: 0.00,
        serviceJob: const InvoiceJob(uuid: 'job-demo-001', jobNumber: 'JOB-2026-0047'),
        customer: const InvoiceCustomer(
          uuid: 'c1',
          fullName: 'Rahul Sharma',
          phone: '+919876543210',
          email: 'rahul.sharma@gmail.com',
        ),
        vehicle: const InvoiceVehicle(
          make: 'Maruti',
          model: 'Swift VXI',
          registrationNumber: 'MH12AB1234',
          year: 2020,
        ),
        items: [
          InvoiceItem(
            uuid: 'item-001',
            lineType: 'service',
            description: 'Engine Oil Change (5W-30 Synthetic)',
            quantity: 1,
            unitPrice: 800,
            taxRate: 18,
            taxAmount: 144,
            lineTotal: 944,
            sortOrder: 1,
          ),
          InvoiceItem(
            uuid: 'item-002',
            lineType: 'part',
            description: 'Bosch Oil Filter',
            quantity: 1,
            unitPrice: 350,
            taxRate: 18,
            taxAmount: 63,
            lineTotal: 413,
            sortOrder: 2,
          ),
          InvoiceItem(
            uuid: 'item-003',
            lineType: 'labour',
            description: 'AC Gas Top-up & Filter Cleaning',
            quantity: 1,
            unitPrice: 1500,
            taxRate: 18,
            taxAmount: 270,
            lineTotal: 1770,
            sortOrder: 3,
          ),
          InvoiceItem(
            uuid: 'item-004',
            lineType: 'service',
            description: 'Brake Fluid Replacement',
            quantity: 1,
            unitPrice: 1200,
            taxRate: 18,
            taxAmount: 216,
            lineTotal: 1416,
            sortOrder: 4,
          ),
          InvoiceItem(
            uuid: 'item-005',
            lineType: 'tax',
            description: 'GST 18%',
            quantity: 1,
            unitPrice: 693,
            taxRate: 0,
            taxAmount: 0,
            lineTotal: 693,
            sortOrder: 5,
          ),
        ],
        payments: [
          PaymentRecord(
            uuid: 'pay-001',
            amount: 4849.80,
            paymentMethod: const InvoicePaymentMethod(name: 'UPI', iconKey: 'upi'),
            referenceNumber: 'UPI2026051512345',
            paidAt: _now.subtract(const Duration(days: 3)),
            notes: 'Paid via PhonePe',
          ),
        ],
      );

    case 'inv-demo-004':
      return InvoiceDetail(
        uuid: 'inv-demo-004',
        invoiceNumber: 'INV-2026-0044',
        status: 'partially_paid',
        issuedDate: _now.subtract(const Duration(days: 2)),
        dueDate: _now.add(const Duration(days: 5)),
        subtotal: 6950.00,
        taxAmount: 1251.00,
        discountAmount: 0.00,
        totalAmount: 8201.00,
        paidAmount: 4000.00,
        balanceDue: 4201.00,
        serviceJob: const InvoiceJob(uuid: 'job-demo-004', jobNumber: 'JOB-2026-0044'),
        customer: const InvoiceCustomer(
          uuid: 'c4',
          fullName: 'Sunita Gupta',
          phone: '+917654321098',
          email: 'sunita.gupta@yahoo.com',
        ),
        vehicle: const InvoiceVehicle(
          make: 'Toyota',
          model: 'Innova Crysta',
          registrationNumber: 'TN09BD3210',
          year: 2019,
        ),
        items: [
          InvoiceItem(
            uuid: 'item-010',
            lineType: 'service',
            description: 'General Service (Major)',
            quantity: 1,
            unitPrice: 3500,
            taxRate: 18,
            taxAmount: 630,
            lineTotal: 4130,
            sortOrder: 1,
          ),
          InvoiceItem(
            uuid: 'item-011',
            lineType: 'part',
            description: 'Brake Pads (Front + Rear)',
            quantity: 2,
            unitPrice: 1200,
            taxRate: 18,
            taxAmount: 432,
            lineTotal: 2832,
            sortOrder: 2,
          ),
          InvoiceItem(
            uuid: 'item-012',
            lineType: 'labour',
            description: 'Brake Service Labour',
            quantity: 1,
            unitPrice: 800,
            taxRate: 18,
            taxAmount: 144,
            lineTotal: 944,
            sortOrder: 3,
          ),
          InvoiceItem(
            uuid: 'item-013',
            lineType: 'discount',
            description: 'Loyalty Discount (5%)',
            quantity: 1,
            unitPrice: -350,
            taxRate: 0,
            taxAmount: 0,
            lineTotal: -350,
            sortOrder: 4,
          ),
        ],
        payments: [
          PaymentRecord(
            uuid: 'pay-010',
            amount: 4000,
            paymentMethod: const InvoicePaymentMethod(name: 'Cash', iconKey: 'cash'),
            paidAt: _now.subtract(const Duration(days: 1)),
          ),
        ],
      );

    default:
      // Generic fallback for other demo UUIDs
      final listItem = invoicesDemoData.data.firstWhere(
        (i) => i.uuid == uuid,
        orElse: () => invoicesDemoData.data.first,
      );
      return InvoiceDetail(
        uuid: listItem.uuid,
        invoiceNumber: listItem.invoiceNumber,
        status: listItem.status,
        issuedDate: listItem.issuedDate,
        dueDate: listItem.dueDate,
        subtotal: listItem.totalAmount * 0.847,
        taxAmount: listItem.totalAmount * 0.153,
        discountAmount: 0,
        totalAmount: listItem.totalAmount,
        paidAmount: listItem.paidAmount,
        balanceDue: listItem.balanceDue,
        serviceJob: listItem.serviceJob,
        customer: listItem.customer,
        vehicle: listItem.vehicle,
        items: [
          InvoiceItem(
            uuid: '${uuid}_item_1',
            lineType: 'service',
            description: 'General Service',
            quantity: 1,
            unitPrice: listItem.totalAmount * 0.5,
            taxRate: 18,
            taxAmount: listItem.totalAmount * 0.09,
            lineTotal: listItem.totalAmount * 0.59,
            sortOrder: 1,
          ),
          InvoiceItem(
            uuid: '${uuid}_item_2',
            lineType: 'part',
            description: 'Spare Parts',
            quantity: 1,
            unitPrice: listItem.totalAmount * 0.3,
            taxRate: 18,
            taxAmount: listItem.totalAmount * 0.054,
            lineTotal: listItem.totalAmount * 0.354,
            sortOrder: 2,
          ),
          InvoiceItem(
            uuid: '${uuid}_item_3',
            lineType: 'labour',
            description: 'Labour Charges',
            quantity: 1,
            unitPrice: listItem.totalAmount * 0.1,
            taxRate: 18,
            taxAmount: listItem.totalAmount * 0.018,
            lineTotal: listItem.totalAmount * 0.118,
            sortOrder: 3,
          ),
        ],
        payments: listItem.paidAmount > 0
            ? [
                PaymentRecord(
                  uuid: '${uuid}_pay_1',
                  amount: listItem.paidAmount,
                  paymentMethod:
                      const InvoicePaymentMethod(name: 'Cash', iconKey: 'cash'),
                  paidAt: listItem.issuedDate,
                ),
              ]
            : [],
      );
  }
}

/// Demo payment methods
List<PaymentMethod> get paymentMethodsDemoData => const [
      PaymentMethod(id: 1, name: 'Cash', iconKey: 'cash'),
      PaymentMethod(id: 2, name: 'UPI', iconKey: 'upi'),
      PaymentMethod(id: 3, name: 'Card', iconKey: 'card'),
      PaymentMethod(id: 4, name: 'Net Banking', iconKey: 'netbanking'),
      PaymentMethod(id: 5, name: 'Cheque', iconKey: 'cheque'),
      PaymentMethod(id: 6, name: 'Insurance', iconKey: 'insurance'),
    ];
