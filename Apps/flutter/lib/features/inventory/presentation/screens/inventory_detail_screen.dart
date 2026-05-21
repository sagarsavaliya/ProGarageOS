import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/inventory_models.dart';
import '../providers/inventory_provider.dart';

class InventoryDetailScreen extends ConsumerWidget {
  final String itemUuid;

  const InventoryDetailScreen({super.key, required this.itemUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryDetailProvider(itemUuid));
    final notifier = ref.read(inventoryDetailProvider(itemUuid).notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: state.when(
        loading: () => const _LoadingView(),
        error: (_, __) => _ErrorView(onRetry: notifier.refresh),
        data: (detail) => _DetailView(
          detail: detail,
          onRefresh: notifier.refresh,
          onAdjustStock: (req) => notifier.adjustStock(req),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main detail view
// ---------------------------------------------------------------------------

class _DetailView extends StatefulWidget {
  final InventoryDetail detail;
  final Future<void> Function() onRefresh;
  final Future<void> Function(AddStockAdjustmentRequest) onAdjustStock;

  const _DetailView({
    required this.detail,
    required this.onRefresh,
    required this.onAdjustStock,
  });

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  bool _loadingQuickAdd10 = false;
  bool _loadingQuickAdd1 = false;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildStockCard(),
                const SizedBox(height: 12),
                _buildInfoCard(),
                const SizedBox(height: 12),
                _buildAdjustSection(context),
                if (widget.detail.recentAdjustments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAdjustmentsSection(),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final detail = widget.detail;
    return SliverAppBar(
      backgroundColor: AppColors.bgSurface,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        icon: Icon(
          PhosphorIconsRegular.caretLeft,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail.name, style: AppTextStyles.titleMedium),
          Text(
            detail.sku,
            style: GoogleFonts.dmMono(
              fontSize: 10,
              color: AppColors.primaryOrange,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: detail.isActive ? AppColors.statusGreenBg : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: detail.isActive ? AppColors.statusGreen : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                detail.isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: detail.isActive ? AppColors.statusGreen : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }

  Widget _buildStockCard() {
    final detail = widget.detail;
    final (stockColor, statusText) = _stockColorAndText(detail.stockStatus);
    final fillValue = detail.maximumStockLevel > 0
        ? (detail.stockQuantity / detail.maximumStockLevel).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stockColor.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Large stock number
              Text(
                '${detail.stockQuantity}',
                style: GoogleFonts.dmMono(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: stockColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.unit,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: stockColor.withAlpha(28),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: stockColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillValue,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation<Color>(stockColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          // Min / Max indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${detail.minimumStockLevel}',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
              ),
              Text(
                'Max: ${detail.maximumStockLevel}',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final detail = widget.detail;
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
    final margin = detail.marginPercent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3-column grid: SKU / Category / Unit
          Row(
            children: [
              Expanded(
                child: _InfoCell(
                  label: 'SKU',
                  value: detail.sku,
                  valueMono: true,
                ),
              ),
              Expanded(
                child: _InfoCell(
                  label: 'Category',
                  value: detail.category.name,
                ),
              ),
              Expanded(
                child: _InfoCell(
                  label: 'Unit',
                  value: detail.unit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          // Price row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Selling Price', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      '₹${currencyFmt.format(detail.sellingPrice)}',
                      style: GoogleFonts.dmMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost Price', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 2),
                    Text(
                      '₹${currencyFmt.format(detail.costPrice)}',
                      style: AppTextStyles.monoSmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Margin', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusGreenBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${margin.toStringAsFixed(1)}%',
                      style: GoogleFonts.dmMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.statusGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (detail.notes != null && detail.notes!.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(PhosphorIconsRegular.notepad, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(detail.notes!, style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(
                PhosphorIconsRegular.arrowsCounterClockwise,
                color: AppColors.primaryOrange,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text('Adjust Stock', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 14),
          // Quick actions
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '+10',
                  variant: AppButtonVariant.secondary,
                  height: 40,
                  isLoading: _loadingQuickAdd10,
                  onPressed: _loadingQuickAdd10 || _loadingQuickAdd1
                      ? null
                      : () => _quickAdd(10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: '+1',
                  variant: AppButtonVariant.secondary,
                  height: 40,
                  isLoading: _loadingQuickAdd1,
                  onPressed: _loadingQuickAdd10 || _loadingQuickAdd1
                      ? null
                      : () => _quickAdd(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Custom',
                  variant: AppButtonVariant.outlined,
                  height: 40,
                  onPressed: _loadingQuickAdd10 || _loadingQuickAdd1
                      ? null
                      : () => _showAdjustSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _quickAdd(int qty) async {
    final req = AddStockAdjustmentRequest(
      type: 'add',
      quantity: qty,
      reason: 'Quick add',
    );
    if (qty == 10) {
      setState(() => _loadingQuickAdd10 = true);
    } else {
      setState(() => _loadingQuickAdd1 = true);
    }
    try {
      await widget.onAdjustStock(req);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $qty ${widget.detail.unit} to stock',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingQuickAdd10 = false;
          _loadingQuickAdd1 = false;
        });
      }
    }
  }

  void _showAdjustSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockAdjustSheet(
        currentStock: widget.detail.stockQuantity,
        unit: widget.detail.unit,
        onAdjust: widget.onAdjustStock,
      ),
    );
  }

  Widget _buildAdjustmentsSection() {
    final adjustments = widget.detail.recentAdjustments;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text('Recent Adjustments', style: AppTextStyles.titleSmall),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${adjustments.length}',
                  style: AppTextStyles.labelSmall,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: adjustments.length,
            itemBuilder: (context, i) {
              final isLast = i == adjustments.length - 1;
              return _AdjustmentRow(
                adjustment: adjustments[i],
                isLast: isLast,
              );
            },
          ),
        ),
      ],
    );
  }

  (Color, String) _stockColorAndText(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return (AppColors.statusRed, 'OUT OF STOCK');
      case StockStatus.lowStock:
        return (AppColors.statusOrange, 'LOW STOCK');
      case StockStatus.adequate:
        return (AppColors.statusGreen, 'IN STOCK');
      case StockStatus.wellStocked:
        return (AppColors.statusTeal, 'WELL STOCKED');
    }
  }
}

// ---------------------------------------------------------------------------
// Info cell — 3-column grid cell
// ---------------------------------------------------------------------------

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final bool valueMono;

  const _InfoCell({
    required this.label,
    required this.value,
    this.valueMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 3),
        Text(
          value,
          style: valueMono
              ? AppTextStyles.monoSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                )
              : AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Adjustment row
// ---------------------------------------------------------------------------

class _AdjustmentRow extends StatelessWidget {
  final StockAdjustment adjustment;
  final bool isLast;

  const _AdjustmentRow({required this.adjustment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM, h:mm a');
    final (iconData, iconColor, iconBg) = _typeStyle(adjustment.type);
    final sign = adjustment.type == 'remove' ? '−' : adjustment.type == 'add' ? '+' : '=';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(adjustment.reason, style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    )),
                    const SizedBox(height: 2),
                    Text(
                      '${adjustment.adjustedBy} · ${dateFmt.format(adjustment.createdAt.toLocal())}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${adjustment.quantity}',
                style: AppTextStyles.monoSmall.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
      ],
    );
  }

  (PhosphorIconData, Color, Color) _typeStyle(String type) {
    switch (type) {
      case 'add':
        return (
          PhosphorIconsRegular.arrowUp,
          AppColors.statusGreen,
          AppColors.statusGreenBg,
        );
      case 'remove':
        return (
          PhosphorIconsRegular.arrowDown,
          AppColors.statusRed,
          AppColors.statusRedBg,
        );
      case 'set':
      default:
        return (
          PhosphorIconsRegular.equals,
          AppColors.statusBlue,
          AppColors.statusBlueBg,
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Stock Adjust Bottom Sheet
// ---------------------------------------------------------------------------

class _StockAdjustSheet extends StatefulWidget {
  final int currentStock;
  final String unit;
  final Future<void> Function(AddStockAdjustmentRequest) onAdjust;

  const _StockAdjustSheet({
    required this.currentStock,
    required this.unit,
    required this.onAdjust,
  });

  @override
  State<_StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends State<_StockAdjustSheet> {
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _quantityFocus = FocusNode();

  String _selectedType = 'add';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quantityFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title row
            Row(
              children: [
                Text('Adjust Stock', style: AppTextStyles.titleLarge),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.x,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Current stock display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text('Current stock:', style: AppTextStyles.bodySmall),
                  const Spacer(),
                  Text(
                    '${widget.currentStock} ${widget.unit}',
                    style: GoogleFonts.dmMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Type selector
            Text('Adjustment Type', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                _TypeChip(
                  label: 'Add',
                  isActive: _selectedType == 'add',
                  color: AppColors.statusGreen,
                  onTap: () => setState(() => _selectedType = 'add'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Remove',
                  isActive: _selectedType == 'remove',
                  color: AppColors.statusRed,
                  onTap: () => setState(() => _selectedType = 'remove'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Set to',
                  isActive: _selectedType == 'set',
                  color: AppColors.statusBlue,
                  onTap: () => setState(() => _selectedType = 'set'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quantity field
            AppTextField(
              controller: _quantityController,
              focusNode: _quantityFocus,
              label: _selectedType == 'set' ? 'Set quantity to' : 'Quantity',
              hint: '0',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            // Reason field
            AppTextField(
              controller: _reasonController,
              label: 'Reason',
              hint: 'Received delivery / Damaged / Audit correction…',
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.statusRedBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.warning, color: AppColors.statusRed, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.statusRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            AppButton(
              label: _submitLabel,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String get _submitLabel {
    switch (_selectedType) {
      case 'add':
        return 'Add Stock';
      case 'remove':
        return 'Remove Stock';
      case 'set':
      default:
        return 'Set Stock';
    }
  }

  Future<void> _submit() async {
    final qtyText = _quantityController.text.trim();
    final qty = int.tryParse(qtyText);
    final reason = _reasonController.text.trim();

    if (qty == null || qty <= 0) {
      setState(() => _errorMessage = 'Please enter a valid quantity greater than 0.');
      return;
    }
    if (_selectedType == 'remove' && qty > widget.currentStock) {
      setState(() =>
          _errorMessage = 'Cannot remove more than current stock (${widget.currentStock}).');
      return;
    }
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Please enter a reason for this adjustment.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onAdjust(
        AddStockAdjustmentRequest(
          type: _selectedType,
          quantity: qty,
          reason: reason,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock updated',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to update stock. Please try again.';
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Type chip for adjust sheet
// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color.withAlpha(30) : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color : AppColors.divider,
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading + error views
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.warning, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          Text('Could not load part details', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          AppButton(
            label: 'Retry',
            variant: AppButtonVariant.ghost,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
