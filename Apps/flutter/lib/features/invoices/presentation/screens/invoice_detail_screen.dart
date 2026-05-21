import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/invoice_models.dart';
import '../providers/invoices_provider.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceUuid;

  const InvoiceDetailScreen({super.key, required this.invoiceUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(invoiceDetailProvider(invoiceUuid));
    final notifier = ref.read(invoiceDetailProvider(invoiceUuid).notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: state.when(
        loading: () => const _LoadingView(),
        error: (_, __) => _ErrorView(onRetry: notifier.refresh),
        data: (detail) => _DetailView(
          detail: detail,
          onRefresh: notifier.refresh,
          onRecordPayment: (req) => notifier.recordPayment(req),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main detail view
// ---------------------------------------------------------------------------

class _DetailView extends StatelessWidget {
  final InvoiceDetail detail;
  final Future<void> Function() onRefresh;
  final Future<void> Function(RecordPaymentRequest) onRecordPayment;

  const _DetailView({
    required this.detail,
    required this.onRefresh,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopCard(context),
                const SizedBox(height: 16),
                _buildSectionHeader('Items', '${detail.items.length}'),
                _buildItemsList(),
                const SizedBox(height: 16),
                _buildSectionHeader('Summary', null),
                _buildFinancialCard(),
                if (detail.payments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionHeader('Payments', '${detail.payments.length}'),
                  _buildPaymentsList(),
                ],
                if (detail.notes != null && detail.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSectionHeader('Notes', null),
                  _buildNotesCard(),
                ],
                const SizedBox(height: 24),
                if (detail.balanceDue > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppButton(
                      label: 'Record Payment',
                      onPressed: () => _showPaymentSheet(context),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
        icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(detail.invoiceNumber, style: AppTextStyles.titleMedium),
          Text(
            detail.serviceJob.jobNumber,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryOrange),
          ),
        ],
      ),
      actions: [
        AppStatusChip(status: detail.status),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }

  Widget _buildTopCard(BuildContext context) {
    final customer = detail.customer;
    final vehicle = detail.vehicle;
    final dateFmt = DateFormat('d MMM yyyy');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer name + contact
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryOrangeDim,
                ),
                child: Center(
                  child: Text(
                    _initials(customer.fullName),
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.fullName, style: AppTextStyles.titleMedium),
                    if (customer.email != null)
                      Text(customer.email!, style: AppTextStyles.bodySmall),
                    Text(customer.phone, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          // Vehicle row
          Row(
            children: [
              Icon(PhosphorIconsRegular.car, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(vehicle.makeModel, style: AppTextStyles.bodyMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vehicle.registrationNumber,
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          // Dates row
          Row(
            children: [
              Expanded(
                child: _DateRow(
                  icon: PhosphorIconsRegular.calendarBlank,
                  label: 'Issued',
                  date: dateFmt.format(detail.issuedDate),
                ),
              ),
              if (detail.dueDate != null)
                Expanded(
                  child: _DateRow(
                    icon: PhosphorIconsRegular.calendarCheck,
                    label: 'Due',
                    date: dateFmt.format(detail.dueDate!),
                    isOverdue: detail.isOverdue,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? badge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(badge, style: AppTextStyles.labelSmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    if (detail.items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(child: Text('No items', style: AppTextStyles.bodySmall)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: detail.items.asMap().entries.map((entry) {
          final isLast = entry.key == detail.items.length - 1;
          return _LineItemRow(item: entry.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildFinancialCard() {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _FinancialRow(label: 'Subtotal', value: '₹${fmt.format(detail.subtotal)}'),
          if (detail.taxAmount > 0) ...[
            const SizedBox(height: 8),
            _FinancialRow(
              label: 'Tax',
              value: '₹${fmt.format(detail.taxAmount)}',
              valueColor: AppColors.textSecondary,
            ),
          ],
          if (detail.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _FinancialRow(
              label: 'Discount',
              value: '−₹${fmt.format(detail.discountAmount)}',
              valueColor: AppColors.statusRed,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.titleMedium),
              Text(
                '₹${fmt.format(detail.totalAmount)}',
                style: GoogleFonts.dmMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Paid
          _FinancialRow(
            label: 'Paid',
            value: '₹${fmt.format(detail.paidAmount)}',
            valueColor: AppColors.statusGreen,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          // Balance due
          if (detail.balanceDue > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.statusRedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        PhosphorIconsRegular.warning,
                        color: AppColors.statusRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Balance Due',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.statusRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${fmt.format(detail.balanceDue)}',
                    style: GoogleFonts.dmMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusRed,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.statusGreenBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIconsFill.checkCircle,
                    color: AppColors.statusGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Paid in Full',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.statusGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: detail.payments.asMap().entries.map((entry) {
          final isLast = entry.key == detail.payments.length - 1;
          return _PaymentRow(payment: entry.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsRegular.notepad, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(detail.notes!, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordPaymentSheet(
        balanceDue: detail.balanceDue,
        invoiceUuid: detail.uuid,
        onRecordPayment: onRecordPayment,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(1, 2)).toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Date row helper
// ---------------------------------------------------------------------------

class _DateRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final String date;
  final bool isOverdue;

  const _DateRow({
    required this.icon,
    required this.label,
    required this.date,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverdue ? AppColors.statusRed : AppColors.textSecondary;
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelSmall),
            Text(
              date,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Line item row
// ---------------------------------------------------------------------------

class _LineItemRow extends StatelessWidget {
  final InvoiceItem item;
  final bool isLast;

  const _LineItemRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final (typeColor, typeBg) = _lineTypeStyle(item.lineType);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.description,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.lineType.toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} × ₹${fmt.format(item.unitPrice)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${fmt.format(item.lineTotal)}',
                style: AppTextStyles.monoSmall.copyWith(
                  color: item.lineType == 'discount'
                      ? AppColors.statusRed
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
      ],
    );
  }

  (Color, Color) _lineTypeStyle(String lineType) {
    switch (lineType) {
      case 'service':
        return (AppColors.statusBlue, AppColors.statusBlueBg);
      case 'part':
        return (AppColors.statusTeal, AppColors.statusTealBg);
      case 'labour':
        return (AppColors.statusOrange, AppColors.statusOrangeBg);
      case 'discount':
        return (AppColors.statusRed, AppColors.statusRedBg);
      case 'fee':
        return (AppColors.statusPurple, AppColors.statusPurpleBg);
      case 'tax':
        return (AppColors.textSecondary, AppColors.bgElevated);
      default:
        return (AppColors.textMuted, AppColors.bgElevated);
    }
  }
}

// ---------------------------------------------------------------------------
// Financial summary row
// ---------------------------------------------------------------------------

class _FinancialRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FinancialRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.monoSmall.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Payment row
// ---------------------------------------------------------------------------

class _PaymentRow extends StatelessWidget {
  final PaymentRecord payment;
  final bool isLast;

  const _PaymentRow({required this.payment, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.statusGreenBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIconsRegular.currencyInr,
                  color: AppColors.statusGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment.paymentMethod.name, style: AppTextStyles.titleSmall),
                    if (payment.referenceNumber != null)
                      Text(
                        'Ref: ${payment.referenceNumber}',
                        style: AppTextStyles.bodySmall,
                      ),
                    Text(
                      dateFmt.format(payment.paidAt.toLocal()),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${fmt.format(payment.amount)}',
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusGreen,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Record Payment bottom sheet
// ---------------------------------------------------------------------------

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final double balanceDue;
  final String invoiceUuid;
  final Future<void> Function(RecordPaymentRequest) onRecordPayment;

  const _RecordPaymentSheet({
    required this.balanceDue,
    required this.invoiceUuid,
    required this.onRecordPayment,
  });

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedMethodId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    _amountController.text = fmt.format(widget.balanceDue);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsProvider);
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
            // Handle + title
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
            Row(
              children: [
                Text('Record Payment', style: AppTextStyles.titleLarge),
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
                    child: Icon(PhosphorIconsRegular.x, color: AppColors.textMuted, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount field
            AppTextField(
              controller: _amountController,
              label: 'Amount',
              hint: '0.00',
              prefixText: '₹ ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Payment method selector
            Text('Payment Method', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            methodsAsync.when(
              loading: () => const SizedBox(
                height: 44,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              error: (_, __) => Text('Failed to load methods', style: AppTextStyles.bodySmall),
              data: (methods) => SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: methods.length,
                  itemBuilder: (context, i) {
                    final method = methods[i];
                    final isSelected = _selectedMethodId == method.id;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedMethodId = method.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryOrange : AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryOrange : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          method.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reference number
            AppTextField(
              controller: _referenceController,
              label: 'Reference Number (optional)',
              hint: 'UPI ID / Transaction ref',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // Notes
            AppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'e.g. Customer paid partial amount',
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
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),
            AppButton(
              label: 'Record Payment',
              isLoading: _isSubmitting,
              onPressed: _selectedMethodId != null ? _submit : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final rawAmount = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onRecordPayment(
        RecordPaymentRequest(
          amount: amount,
          paymentMethodId: _selectedMethodId!,
          referenceNumber: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment recorded successfully',
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
          _errorMessage = 'Failed to record payment. Please try again.';
        });
      }
    }
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
          Text('Could not load invoice', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.dmSans(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
