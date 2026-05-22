import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/guided_empty_state.dart';
import '../../../invoices/data/invoices_repository.dart';
import '../../../invoices/presentation/widgets/record_payment_sheet.dart';
import '../../data/models/outstanding_models.dart';
import '../providers/payments_hub_provider.dart';

class PaymentsHubScreen extends ConsumerStatefulWidget {
  const PaymentsHubScreen({super.key});

  @override
  ConsumerState<PaymentsHubScreen> createState() => _PaymentsHubScreenState();
}

class _PaymentsHubScreenState extends ConsumerState<PaymentsHubScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsHubProvider);
    final notifier = ref.read(paymentsHubProvider.notifier);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payments', style: AppTextStyles.displayMedium),
                        Text('Collect outstanding dues', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/invoices'),
                    child: const Text('All invoices'),
                  ),
                  IconButton(
                    onPressed: notifier.refresh,
                    icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total outstanding', style: AppTextStyles.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(state.totalOutstanding),
                      style: AppTextStyles.displayMedium.copyWith(color: AppColors.statusOrange),
                    ),
                    Text(
                      '${state.invoices.length} open invoice${state.invoices.length == 1 ? '' : 's'}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search customer, plate, invoice…',
                  prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: notifier.setSearch,
              ),
            ),
            Expanded(child: _buildList(context, state, notifier, currency)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    PaymentsHubState state,
    PaymentsHubNotifier notifier,
    NumberFormat currency,
  ) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }
    if (state.error != null && state.invoices.isEmpty) {
      return ApiErrorView(message: state.error!, onRetry: notifier.refresh);
    }
    if (state.invoices.isEmpty) {
      return GuidedEmptyState(
        icon: PhosphorIconsRegular.currencyInr,
        title: 'All caught up',
        subtitle: 'No outstanding payments right now.',
        actionLabel: 'View invoices',
        onAction: () => context.push('/invoices'),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= state.invoices.length) {
            notifier.loadMore();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
              ),
            );
          }
          final inv = state.invoices[index];
          return _OutstandingCard(
            invoice: inv,
            currency: currency,
            onCollect: () => _collectPayment(context, inv),
            onOpen: () => context.push('/invoices/${inv.uuid}'),
          );
        },
      ),
    );
  }

  Future<void> _collectPayment(BuildContext context, OutstandingInvoice inv) async {
    await showRecordPaymentSheet(
      context: context,
      balanceDue: inv.balanceDue,
      onRecordPayment: (req) async {
        await ref.read(invoicesRepositoryProvider).recordPayment(inv.uuid, req);
        ref.read(paymentsHubProvider.notifier).refresh();
      },
    );
  }
}

class _OutstandingCard extends StatelessWidget {
  final OutstandingInvoice invoice;
  final NumberFormat currency;
  final VoidCallback onCollect;
  final VoidCallback onOpen;

  const _OutstandingCard({
    required this.invoice,
    required this.currency,
    required this.onCollect,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(invoice.customerName, style: AppTextStyles.titleSmall),
                  ),
                  AppStatusChip(status: invoice.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${invoice.invoiceNumber} · ${invoice.vehicleRegistration}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                currency.format(invoice.balanceDue),
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onCollect();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Collect payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
