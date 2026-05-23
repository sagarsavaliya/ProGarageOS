import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../data/models/job_models.dart';
import '../providers/jobs_provider.dart';

class JobInsuranceCard extends ConsumerStatefulWidget {
  final String jobUuid;
  final JobInsuranceClaim claim;
  final bool readOnly;

  const JobInsuranceCard({
    super.key,
    required this.jobUuid,
    required this.claim,
    this.readOnly = false,
  });

  @override
  ConsumerState<JobInsuranceCard> createState() => _JobInsuranceCardState();
}

class _JobInsuranceCardState extends ConsumerState<JobInsuranceCard> {
  late final TextEditingController _companyController;
  late final TextEditingController _claimController;
  late final TextEditingController _customerPayController;
  late final TextEditingController _insurancePayController;
  bool _isSaving = false;

  static const _statusSteps = [
    ('survey_pending', 'Survey pending'),
    ('estimate_submitted', 'Estimate sent'),
    ('approved', 'Approved'),
    ('rejected', 'Rejected'),
    ('settled', 'Settled'),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.claim;
    _companyController = TextEditingController(text: c.insuranceCompany ?? '');
    _claimController = TextEditingController(text: c.claimNumber ?? '');
    _customerPayController = TextEditingController(
      text: c.customerLiabilityAmount?.toStringAsFixed(0) ?? '',
    );
    _insurancePayController = TextEditingController(
      text: c.insuranceClaimAmount?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _claimController.dispose();
    _customerPayController.dispose();
    _insurancePayController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JobInsuranceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.claim != widget.claim) {
      _companyController.text = widget.claim.insuranceCompany ?? '';
      _claimController.text = widget.claim.claimNumber ?? '';
      _customerPayController.text =
          widget.claim.customerLiabilityAmount?.toStringAsFixed(0) ?? '';
      _insurancePayController.text =
          widget.claim.insuranceClaimAmount?.toStringAsFixed(0) ?? '';
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(jobDetailProvider(widget.jobUuid).notifier).updateInsuranceClaim(
            insuranceClaimStatus: status,
            insuranceCompany: _companyController.text.trim(),
            claimNumber: _claimController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim status updated', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update claim status', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.statusRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSplit() async {
    final customer = double.tryParse(_customerPayController.text.replaceAll(RegExp(r'[^\d.]'), ''));
    final insurance = double.tryParse(_insurancePayController.text.replaceAll(RegExp(r'[^\d.]'), ''));
    setState(() => _isSaving = true);
    try {
      await ref.read(jobDetailProvider(widget.jobUuid).notifier).updateInsuranceClaim(
            insuranceCompany: _companyController.text.trim(),
            claimNumber: _claimController.text.trim(),
            customerLiabilityAmount: customer,
            jobInsuranceClaimAmount: insurance,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim details saved', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.statusGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save claim details', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.statusRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.claim.status;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.shield, color: AppColors.primaryOrange, size: 18),
              const SizedBox(width: 8),
              Text('Insurance claim', style: AppTextStyles.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _companyController,
            readOnly: widget.readOnly,
            decoration: InputDecoration(
              labelText: 'Insurance company',
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _claimController,
            readOnly: widget.readOnly,
            decoration: InputDecoration(
              labelText: 'Claim number',
              filled: true,
              fillColor: AppColors.bgPrimary,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          Text('Claim status', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 2.4,
            children: _statusSteps.map((step) {
              final selected = current == step.$1;
              return AppFilterChip(
                label: step.$2,
                isSelected: selected,
                compact: true,
                onTap: widget.readOnly || _isSaving ? () {} : () => _updateStatus(step.$1),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Estimated split (₹)', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerPayController,
                  readOnly: widget.readOnly,
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
                  controller: _insurancePayController,
                  readOnly: widget.readOnly,
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
          if (!widget.readOnly)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () {
                  HapticFeedback.lightImpact();
                  _saveSplit();
                },
                child: Text(
                  _isSaving ? 'Saving…' : 'Save claim details',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
