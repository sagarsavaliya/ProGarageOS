import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../jobs/data/models/job_models.dart';
import '../providers/create_invoice_provider.dart';
import '../providers/invoices_provider.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final String? jobUuid;

  const CreateInvoiceScreen({super.key, this.jobUuid});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createInvoiceProvider(widget.jobUuid));
    final notifier = ref.read(createInvoiceProvider(widget.jobUuid).notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        title: Text('New Invoice', style: AppTextStyles.titleMedium),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
        ),
      ),
      body: state.isLoadingJobs
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Select job', style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                ...state.billableJobs.map((job) => _JobTile(
                      job: job,
                      selected: state.selectedJob?.uuid == job.uuid,
                      onTap: () => notifier.selectJob(job),
                    )),
                if (state.billableJobs.isEmpty)
                  Text('No billable jobs found', style: AppTextStyles.bodySmall),
                if (state.selectedJob != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Line items', style: AppTextStyles.titleSmall),
                      TextButton.icon(
                        onPressed: notifier.addLine,
                        icon: const Icon(PhosphorIconsRegular.plus, size: 16),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  ...state.lines.asMap().entries.map((e) {
                    return _LineEditor(
                      index: e.key,
                      line: e.value,
                      onChanged: (l) => notifier.updateLine(e.key, l),
                      onRemove: state.lines.length > 1
                          ? () => notifier.removeLine(e.key)
                          : null,
                    );
                  }),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: AppTextStyles.bodyMedium),
                      Text(
                        '₹${state.subtotal.toStringAsFixed(0)}',
                        style: GoogleFonts.dmMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppButton(
                    label: state.isSubmitting ? 'Creating…' : 'Create invoice',
                    onPressed: state.isSubmitting
                        ? null
                        : () async {
                            final uuid = await notifier.submit();
                            if (uuid != null && context.mounted) {
                              ref.read(invoicesProvider.notifier).refresh();
                              context.pop();
                              context.push('/invoices/$uuid');
                            }
                          },
                  ),
                ],
              ],
            ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final Job job;
  final bool selected;
  final VoidCallback onTap;

  const _JobTile({
    required this.job,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.primaryOrange : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        tileColor: AppColors.bgSurface,
        title: Text(job.jobNumber, style: AppTextStyles.titleSmall),
        subtitle: Text(
          '${job.customer.name} · ${job.vehicle.registrationNumber}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: AppStatusChip(status: job.status.apiValue),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      ),
    );
  }
}

class _LineEditor extends StatefulWidget {
  final int index;
  final InvoiceLineDraft line;
  final ValueChanged<InvoiceLineDraft> onChanged;
  final VoidCallback? onRemove;

  const _LineEditor({
    required this.index,
    required this.line,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.line.name);
    _qty = TextEditingController(text: '${widget.line.quantity}');
    _price = TextEditingController(text: '${widget.line.unitPrice}');
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(InvoiceLineDraft(
      lineType: widget.line.lineType,
      name: _name.text,
      quantity: double.tryParse(_qty.text) ?? 1,
      unitPrice: double.tryParse(_price.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          TextField(
            controller: _name,
            style: AppTextStyles.bodyMedium,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate (₹)'),
                  onChanged: (_) => _emit(),
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(PhosphorIconsRegular.trash, color: AppColors.statusRed),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
