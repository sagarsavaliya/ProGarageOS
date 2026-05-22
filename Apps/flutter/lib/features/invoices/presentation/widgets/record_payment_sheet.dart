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
import '../../data/models/invoice_models.dart';
import '../providers/invoices_provider.dart';

Future<void> showRecordPaymentSheet({
  required BuildContext context,
  required double balanceDue,
  required Future<void> Function(RecordPaymentRequest request) onRecordPayment,
  bool allowInsuranceClaim = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecordPaymentSheet(
      balanceDue: balanceDue,
      onRecordPayment: onRecordPayment,
      allowInsuranceClaim: allowInsuranceClaim,
    ),
  );
}

class RecordPaymentSheet extends ConsumerStatefulWidget {
  final double balanceDue;
  final Future<void> Function(RecordPaymentRequest) onRecordPayment;
  final bool allowInsuranceClaim;

  const RecordPaymentSheet({
    super.key,
    required this.balanceDue,
    required this.onRecordPayment,
    this.allowInsuranceClaim = false,
  });

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedMethodId;
  String _paymentType = 'customer_pay';
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
                Text('Collect Payment', style: AppTextStyles.titleLarge),
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
            AppTextField(
              controller: _amountController,
              label: 'Amount',
              hint: '0.00',
              prefixText: '₹ ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            if (widget.allowInsuranceClaim) ...[
              const SizedBox(height: 14),
              Text('Payment type', style: AppTextStyles.labelMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Customer'),
                      selected: _paymentType == 'customer_pay',
                      onSelected: (_) => setState(() => _paymentType = 'customer_pay'),
                      selectedColor: AppColors.primaryOrangeDim,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Insurance'),
                      selected: _paymentType == 'insurance_claim',
                      onSelected: (_) => setState(() => _paymentType = 'insurance_claim'),
                      selectedColor: AppColors.primaryOrangeDim,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text('Payment Method', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            methodsAsync.when(
              loading: () => const SizedBox(
                height: 44,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
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
            AppTextField(
              controller: _referenceController,
              label: 'Reference Number (optional)',
              hint: 'UPI ID / Transaction ref',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'e.g. Customer paid partial amount',
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
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
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Record Payment',
              isLoading: _isSubmitting,
              onPressed: _selectedMethodId != null ? _submit : null,
            ),
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
          paymentType: _paymentType,
          referenceNumber: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment recorded', style: GoogleFonts.dmSans(color: Colors.white)),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to record payment. Please try again.';
        });
      }
    }
  }
}
