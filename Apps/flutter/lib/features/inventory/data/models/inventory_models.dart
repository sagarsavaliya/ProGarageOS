// Inventory / Parts management data models — aligned with GET /api/inventory
// and GET /api/inventory/{uuid}.

// ---------------------------------------------------------------------------
// StockStatus enum
// ---------------------------------------------------------------------------

enum StockStatus { outOfStock, lowStock, adequate, wellStocked }

// ---------------------------------------------------------------------------
// PartsCategory
// ---------------------------------------------------------------------------

class PartsCategory {
  final int id;
  final String name;

  const PartsCategory({required this.id, required this.name});

  factory PartsCategory.fromJson(Map<String, dynamic> json) => PartsCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// InventoryItem — list item + base model
// ---------------------------------------------------------------------------

class InventoryItem {
  final String uuid;
  final String name;
  final String sku;
  final PartsCategory category;
  final String unit;
  final double sellingPrice;
  final double costPrice;
  final int stockQuantity;
  final int minimumStockLevel;
  final int maximumStockLevel;
  final bool isActive;
  final String? notes;

  const InventoryItem({
    required this.uuid,
    required this.name,
    required this.sku,
    required this.category,
    required this.unit,
    required this.sellingPrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.minimumStockLevel,
    required this.maximumStockLevel,
    required this.isActive,
    this.notes,
  });

  // Computed getters
  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => !isOutOfStock && stockQuantity <= minimumStockLevel;

  StockStatus get stockStatus {
    if (isOutOfStock) return StockStatus.outOfStock;
    if (isLowStock) return StockStatus.lowStock;
    final fillRatio = maximumStockLevel > 0 ? stockQuantity / maximumStockLevel : 1.0;
    if (fillRatio >= 0.6) return StockStatus.wellStocked;
    return StockStatus.adequate;
  }

  double get marginPercent {
    if (sellingPrice <= 0) return 0;
    return (sellingPrice - costPrice) / sellingPrice * 100;
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final m = json.containsKey('uuid') ? json : (json['item'] as Map<String, dynamic>? ?? json);
    return InventoryItem._fromMap(m);
  }

  factory InventoryItem._fromMap(Map<String, dynamic> json) => InventoryItem(
        uuid: json['uuid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        category: json['category'] is String
            ? PartsCategory(id: 0, name: json['category'] as String)
            : PartsCategory.fromJson(
                json['category'] as Map<String, dynamic>? ?? {},
              ),
        unit: json['unit'] as String? ?? json['unit_of_measure'] as String? ?? 'piece',
        sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0,
        costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0,
        stockQuantity: (json['stock_quantity'] as num?)?.toInt() ??
            (json['stock_on_hand'] as num?)?.toInt() ??
            0,
        minimumStockLevel: (json['minimum_stock_level'] as num?)?.toInt() ??
            (json['low_stock_threshold'] as num?)?.toInt() ??
            0,
        maximumStockLevel: (json['maximum_stock_level'] as num?)?.toInt() ?? 100,
        isActive: (json['is_active'] as bool?) ?? true,
        notes: json['notes'] as String?,
      );
}

// ---------------------------------------------------------------------------
// StockAdjustment — single adjustment record
// ---------------------------------------------------------------------------

class StockAdjustment {
  final String type; // add | remove | set
  final int quantity;
  final String reason;
  final String adjustedBy;
  final DateTime createdAt;

  const StockAdjustment({
    required this.type,
    required this.quantity,
    required this.reason,
    required this.adjustedBy,
    required this.createdAt,
  });

  factory StockAdjustment.fromJson(Map<String, dynamic> json) => StockAdjustment(
        type: json['type'] as String? ?? 'add',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? '',
        adjustedBy: json['adjusted_by'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// InventoryDetail — detail with recent adjustments
// ---------------------------------------------------------------------------

class InventoryDetail {
  final InventoryItem item;
  final List<StockAdjustment> recentAdjustments;

  const InventoryDetail({required this.item, required this.recentAdjustments});

  // Delegate common getters for convenience
  String get uuid => item.uuid;
  String get name => item.name;
  String get sku => item.sku;
  PartsCategory get category => item.category;
  String get unit => item.unit;
  double get sellingPrice => item.sellingPrice;
  double get costPrice => item.costPrice;
  int get stockQuantity => item.stockQuantity;
  int get minimumStockLevel => item.minimumStockLevel;
  int get maximumStockLevel => item.maximumStockLevel;
  bool get isActive => item.isActive;
  String? get notes => item.notes;
  bool get isOutOfStock => item.isOutOfStock;
  bool get isLowStock => item.isLowStock;
  StockStatus get stockStatus => item.stockStatus;
  double get marginPercent => item.marginPercent;

  factory InventoryDetail.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return InventoryDetail(
      item: InventoryItem.fromJson(data),
      recentAdjustments: (data['recent_adjustments'] as List<dynamic>?)
              ?.map((e) => StockAdjustment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Returns a copy with an updated stock quantity (optimistic update).
  InventoryDetail withStockQuantity(int newQty) {
    return InventoryDetail(
      item: InventoryItem(
        uuid: item.uuid,
        name: item.name,
        sku: item.sku,
        category: item.category,
        unit: item.unit,
        sellingPrice: item.sellingPrice,
        costPrice: item.costPrice,
        stockQuantity: newQty,
        minimumStockLevel: item.minimumStockLevel,
        maximumStockLevel: item.maximumStockLevel,
        isActive: item.isActive,
        notes: item.notes,
      ),
      recentAdjustments: recentAdjustments,
    );
  }
}

// ---------------------------------------------------------------------------
// AddStockAdjustmentRequest
// ---------------------------------------------------------------------------

class AddStockAdjustmentRequest {
  final String type; // add | remove | set
  final int quantity;
  final String reason;

  const AddStockAdjustmentRequest({
    required this.type,
    required this.quantity,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'quantity': quantity,
        'reason': reason,
      };
}

// ---------------------------------------------------------------------------
// PaginatedInventory
// ---------------------------------------------------------------------------

class PaginatedInventory {
  final List<InventoryItem> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedInventory({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginatedInventory.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedInventory(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Demo / fallback data — 12 items across 4 categories
// ---------------------------------------------------------------------------

final _demoNow = DateTime.now();

const _catLubricants = PartsCategory(id: 1, name: 'Lubricants');
const _catFilters = PartsCategory(id: 2, name: 'Filters');
const _catBrakeParts = PartsCategory(id: 3, name: 'Brake Parts');
const _catElectrical = PartsCategory(id: 4, name: 'Electrical');

List<PartsCategory> get partsCategoriesDemoData => const [
      _catLubricants,
      _catFilters,
      _catBrakeParts,
      _catElectrical,
    ];

PaginatedInventory get inventoryDemoData => PaginatedInventory(
      currentPage: 1,
      lastPage: 1,
      total: 12,
      data: const [
        // Lubricants — 3 items
        InventoryItem(
          uuid: 'inv-demo-001',
          name: 'Engine Oil 5W-30 Synthetic',
          sku: 'OIL-5W30-1L',
          category: _catLubricants,
          unit: 'litre',
          sellingPrice: 350.00,
          costPrice: 275.00,
          stockQuantity: 45,
          minimumStockLevel: 10,
          maximumStockLevel: 100,
          isActive: true,
          notes: 'Premium synthetic oil. Store below 40°C.',
        ),
        InventoryItem(
          uuid: 'inv-demo-002',
          name: 'Gear Oil 80W-90',
          sku: 'OIL-GEAR-80W90',
          category: _catLubricants,
          unit: 'litre',
          sellingPrice: 220.00,
          costPrice: 170.00,
          stockQuantity: 0,
          minimumStockLevel: 5,
          maximumStockLevel: 50,
          isActive: true,
        ),
        InventoryItem(
          uuid: 'inv-demo-003',
          name: 'Brake Fluid DOT 4',
          sku: 'FLU-DOT4-500',
          category: _catLubricants,
          unit: 'bottle',
          sellingPrice: 180.00,
          costPrice: 130.00,
          stockQuantity: 4,
          minimumStockLevel: 5,
          maximumStockLevel: 30,
          isActive: true,
          notes: 'DOT 4 rated. Replace every 2 years.',
        ),
        // Filters — 3 items
        InventoryItem(
          uuid: 'inv-demo-004',
          name: 'Bosch Oil Filter',
          sku: 'FIL-OIL-BSCH',
          category: _catFilters,
          unit: 'pcs',
          sellingPrice: 350.00,
          costPrice: 210.00,
          stockQuantity: 28,
          minimumStockLevel: 8,
          maximumStockLevel: 60,
          isActive: true,
        ),
        InventoryItem(
          uuid: 'inv-demo-005',
          name: 'Air Filter — Maruti Suzuki',
          sku: 'FIL-AIR-MARTI',
          category: _catFilters,
          unit: 'pcs',
          sellingPrice: 420.00,
          costPrice: 290.00,
          stockQuantity: 3,
          minimumStockLevel: 5,
          maximumStockLevel: 40,
          isActive: true,
        ),
        InventoryItem(
          uuid: 'inv-demo-006',
          name: 'Cabin Air Filter Universal',
          sku: 'FIL-CABIN-UNI',
          category: _catFilters,
          unit: 'pcs',
          sellingPrice: 650.00,
          costPrice: 450.00,
          stockQuantity: 12,
          minimumStockLevel: 4,
          maximumStockLevel: 30,
          isActive: true,
        ),
        // Brake Parts — 3 items
        InventoryItem(
          uuid: 'inv-demo-007',
          name: 'Front Brake Pads (Brembo)',
          sku: 'BRK-PAD-BRMBO-F',
          category: _catBrakeParts,
          unit: 'set',
          sellingPrice: 1800.00,
          costPrice: 1200.00,
          stockQuantity: 0,
          minimumStockLevel: 2,
          maximumStockLevel: 20,
          isActive: true,
        ),
        InventoryItem(
          uuid: 'inv-demo-008',
          name: 'Rear Brake Pads (OEM)',
          sku: 'BRK-PAD-OEM-R',
          category: _catBrakeParts,
          unit: 'set',
          sellingPrice: 1200.00,
          costPrice: 800.00,
          stockQuantity: 7,
          minimumStockLevel: 3,
          maximumStockLevel: 20,
          isActive: true,
        ),
        InventoryItem(
          uuid: 'inv-demo-009',
          name: 'Brake Disc Rotor (Front)',
          sku: 'BRK-DISC-F-260',
          category: _catBrakeParts,
          unit: 'pcs',
          sellingPrice: 2400.00,
          costPrice: 1700.00,
          stockQuantity: 2,
          minimumStockLevel: 2,
          maximumStockLevel: 15,
          isActive: true,
        ),
        // Electrical — 3 items
        InventoryItem(
          uuid: 'inv-demo-010',
          name: 'NGK Spark Plug BKR6E',
          sku: 'ELC-PLUG-NGK6E',
          category: _catElectrical,
          unit: 'pcs',
          sellingPrice: 280.00,
          costPrice: 180.00,
          stockQuantity: 60,
          minimumStockLevel: 12,
          maximumStockLevel: 100,
          isActive: true,
        ),
        InventoryItem(
          uuid: 'inv-demo-011',
          name: 'Car Battery 35Ah',
          sku: 'ELC-BAT-35AH',
          category: _catElectrical,
          unit: 'pcs',
          sellingPrice: 4200.00,
          costPrice: 3200.00,
          stockQuantity: 4,
          minimumStockLevel: 3,
          maximumStockLevel: 15,
          isActive: true,
        ),
        InventoryItem(
          uuid: 'inv-demo-012',
          name: 'H4 Headlight Bulb Pair',
          sku: 'ELC-BLB-H4-PH',
          category: _catElectrical,
          unit: 'pair',
          sellingPrice: 380.00,
          costPrice: 240.00,
          stockQuantity: 15,
          minimumStockLevel: 6,
          maximumStockLevel: 40,
          isActive: true,
        ),
      ],
    );

/// Demo detail data by UUID — includes recent adjustments.
InventoryDetail inventoryDetailDemoData(String uuid) {
  final listItem = inventoryDemoData.data.firstWhere(
    (i) => i.uuid == uuid,
    orElse: () => inventoryDemoData.data.first,
  );

  final adjustments = <StockAdjustment>[
    StockAdjustment(
      type: 'add',
      quantity: 20,
      reason: 'Received delivery from supplier',
      adjustedBy: 'Rajan Kumar',
      createdAt: _demoNow.subtract(const Duration(days: 2)),
    ),
    StockAdjustment(
      type: 'remove',
      quantity: 3,
      reason: 'Used in Job JOB-2026-0044',
      adjustedBy: 'System',
      createdAt: _demoNow.subtract(const Duration(days: 1)),
    ),
    StockAdjustment(
      type: 'set',
      quantity: listItem.stockQuantity,
      reason: 'Monthly stock audit correction',
      adjustedBy: 'Rajan Kumar',
      createdAt: _demoNow.subtract(const Duration(hours: 5)),
    ),
  ];

  return InventoryDetail(item: listItem, recentAdjustments: adjustments);
}
