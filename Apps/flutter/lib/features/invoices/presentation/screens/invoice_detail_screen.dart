import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../data/models/invoice_models.dart';
import '../providers/invoices_provider.dart';
import '../widgets/record_payment_sheet.dart';

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
        error: (err, _) => _ErrorView(message: err.toString(), onRetry: notifier.refresh),
        data: (detail) => _DetailView(
          invoiceUuid: invoiceUuid,
          detail: detail,
          onRefresh: notifier.refresh,
          onRecordPayment: (req) => notifier.recordPayment(req),
          onUpdateSplitBilling: notifier.updateSplitBilling,
          onGeneratePdf: () => notifier.generatePdfUrl(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main detail view
// ---------------------------------------------------------------------------

class _DetailView extends ConsumerStatefulWidget {
  final String invoiceUuid;
  final InvoiceDetail detail;
  final Future<void> Function() onRefresh;
  final Future<void> Function(RecordPaymentRequest) onRecordPayment;
  final Future<void> Function({
    required double customerPayAmount,
    required double insuranceClaimAmount,
  }) onUpdateSplitBilling;
  final Future<String> Function() onGeneratePdf;

  const _DetailView({
    required this.invoiceUuid,
    required this.detail,
    required this.onRefresh,
    required this.onRecordPayment,
    required this.onUpdateSplitBilling,
    required this.onGeneratePdf,
  });

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  bool _pdfLoading = false;

  InvoiceDetail get detail => widget.detail;

  Future<void> _openPdf({required bool share}) async {
    if (_pdfLoading) return;
    setState(() => _pdfLoading = true);
    try {
      final url = detail.pdfUrl ?? await widget.onGeneratePdf();
      final uri = Uri.parse(url);
      if (share) {
        await Share.share(url, subject: 'Invoice ${detail.invoiceNumber}');
      } else {
        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open invoice PDF')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

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
                _buildTopCard(context),
                const SizedBox(height: 16),
                _buildSectionHeader('Items', '${detail.items.length}'),
                _buildItemsList(),
                const SizedBox(height: 16),
                _buildSectionHeader('Summary', null),
                _buildFinancialCard(),
                const SizedBox(height: 12),
                _buildSplitBillingCard(context),
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

  bool get _hasInsuranceSplit =>
      detail.customerPayAmount != null || detail.insuranceClaimAmount != null;

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
        if (_pdfLoading)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
            ),
          )
        else ...[
          IconButton(
            tooltip: 'View PDF',
            onPressed: () => _openPdf(share: false),
            icon: Icon(PhosphorIconsRegular.filePdf, color: AppColors.textSecondary, size: 20),
          ),
          IconButton(
            tooltip: 'Share PDF',
            onPressed: () => _openPdf(share: true),
            icon: Icon(PhosphorIconsRegular.shareNetwork, color: AppColors.textSecondary, size: 20),
          ),
        ],
        AppStatusChip(status: detail.status),
        const SizedBox(width: 8),
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

  Widget _buildSplitBillingCard(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final customerCtrl = TextEditingController(
      text: (detail.customerPayAmount ?? detail.totalAmount).toStringAsFixed(0),
    );
    final insuranceCtrl = TextEditingController(
      text: (detail.insuranceClaimAmount ?? 0).toStringAsFixed(0),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.shield, color: AppColors.primaryOrange, size: 16),
              const SizedBox(width: 8),
              Text('Insurance split billing', style: AppTextStyles.titleSmall),
            ],
          ),
          if (_hasInsuranceSplit) ...[
            const SizedBox(height: 8),
            Text(
              'Customer ₹${fmt.format(detail.customerPayAmount ?? 0)} · '
              'Insurer ₹${fmt.format(detail.insuranceClaimAmount ?? 0)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customerCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Customer pays',
                    filled: true,
                    fillColor: AppColors.bgPrimary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: insuranceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Insurer pays',
                    filled: true,
                    fillColor: AppColors.bgPrimary,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final customer = double.tryParse(customerCtrl.text.replaceAll(',', ''));
                final insurance = double.tryParse(insuranceCtrl.text.replaceAll(',', ''));
                if (customer == null || insurance == null) return;
                await widget.onUpdateSplitBilling(
                  customerPayAmount: customer,
                  insuranceClaimAmount: insurance,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Split billing saved')),
                  );
                }
              },
              child: const Text('Save split'),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showRecordPaymentSheet(
      context: context,
      balanceDue: detail.balanceDue,
      onRecordPayment: widget.onRecordPayment,
      allowInsuranceClaim: true,
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
  final String? message;

  const _ErrorView({required this.onRetry, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.warning, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          Text('Could not load invoice', style: AppTextStyles.titleMedium),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
