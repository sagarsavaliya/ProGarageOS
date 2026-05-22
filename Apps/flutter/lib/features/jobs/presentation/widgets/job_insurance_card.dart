import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/job_models.dart';
import '../providers/jobs_provider.dart';

class JobInsuranceCard extends ConsumerStatefulWidget {
  final String jobUuid;
  final JobInsuranceClaim claim;

  const JobInsuranceCard({
    super.key,
    required this.jobUuid,
    required this.claim,
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

  Future<void> _updateStatus(String status) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(jobDetailProvider(widget.jobUuid).notifier).updateInsuranceClaim(
            insuranceClaimStatus: status,
            insuranceCompany: _companyController.text.trim(),
            claimNumber: _claimController.text.trim(),
          );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveSplit() async {
    final customer = double.tryParse(_customerPayController.text.replaceAll(',', ''));
    final insurance = double.tryParse(_insurancePayController.text.replaceAll(',', ''));
    setState(() => _isSaving = true);
    try {
      await ref.read(jobDetailProvider(widget.jobUuid).notifier).updateInsuranceClaim(
            insuranceCompany: _companyController.text.trim(),
            claimNumber: _claimController.text.trim(),
            customerLiabilityAmount: customer,
            jobInsuranceClaimAmount: insurance,
          );
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
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _statusSteps.map((step) {
              final selected = current == step.$1;
              return ChoiceChip(
                label: Text(step.$2, style: AppTextStyles.labelSmall),
                selected: selected,
                onSelected: _isSaving ? null : (_) => _updateStatus(step.$1),
                selectedColor: AppColors.primaryOrangeDim,
                side: BorderSide(
                  color: selected ? AppColors.primaryOrange : AppColors.divider,
                ),
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
