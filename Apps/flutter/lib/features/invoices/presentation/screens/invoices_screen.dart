import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/guided_empty_state.dart';
import '../../../../core/widgets/quick_action_chip.dart';
import '../../data/invoices_repository.dart';
import '../widgets/record_payment_sheet.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../data/models/invoice_models.dart';
import '../providers/invoices_provider.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoicesProvider);
    final notifier = ref.read(invoicesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/invoices/add');
        },
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(PhosphorIconsRegular.plus, size: 24),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(state, notifier),
            _buildSearchBar(notifier),
            _buildFilterTabs(notifier),
            Expanded(child: _buildList(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InvoicesState state, InvoicesNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoices', style: AppTextStyles.displayMedium),
                if (!state.isLoading)
                  Row(
                    children: [
                      Text(
                        '${state.invoices.length} invoice${state.invoices.length == 1 ? '' : 's'}',
                        style: AppTextStyles.bodySmall,
                      ),
                      if (state.statusFilter != null) ...[
                        Text(' · filtered', style: AppTextStyles.bodySmall),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              notifier.refresh();
            },
            icon: Icon(
              PhosphorIconsRegular.arrowCounterClockwise,
              color: AppColors.textSecondary,
              size: 22,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(InvoicesNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) { setState(() {}); notifier.setSearch(v); },
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search invoice #, customer or job…',
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
            prefixIcon: Icon(
              PhosphorIconsRegular.magnifyingGlass,
              color: AppColors.textMuted,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(PhosphorIconsRegular.x, color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      notifier.setSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(InvoicesNotifier notifier) {
    return AppFilterChipsBar(
      children: [
        for (var i = 0; i < invoiceFilterTabLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AppFilterChip(
            label: invoiceFilterTabLabels[i],
            isSelected: _selectedTabIndex == i,
            onTap: () {
              setState(() => _selectedTabIndex = i);
              notifier.setStatusFilter(invoiceFilterTabs[i]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildList(BuildContext context, InvoicesState state, InvoicesNotifier notifier) {
    if (state.isLoading) return _buildShimmerList();
    if (state.errorMessage != null && state.invoices.isEmpty) {
      return _buildError(state.errorMessage!, notifier);
    }

    // Local instant filter against already-loaded items
    final searchText = _searchController.text.toLowerCase().trim();
    final displayInvoices = searchText.isEmpty
        ? state.invoices
        : state.invoices.where((inv) {
            return inv.invoiceNumber.toLowerCase().contains(searchText) ||
                inv.customer.fullName.toLowerCase().contains(searchText) ||
                inv.serviceJob.jobNumber.toLowerCase().contains(searchText);
          }).toList();

    if (displayInvoices.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: displayInvoices.length + (state.hasMore && searchText.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayInvoices.length) {
            notifier.loadMore();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            );
          }
          return _InvoiceListTile(
            invoice: displayInvoices[index],
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/invoices/${displayInvoices[index].uuid}');
            },
            onCollect: displayInvoices[index].balanceDue > 0
                ? () async {
                    final invoice = displayInvoices[index];
                    final repo = ref.read(invoicesRepositoryProvider);
                    await showRecordPaymentSheet(
                      context: context,
                      balanceDue: invoice.balanceDue,
                      onRecordPayment: (req) async {
                        await repo.recordPayment(invoice.uuid, req);
                        await notifier.refresh();
                      },
                    );
                  }
                : null,
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: 6,
      itemBuilder: (_, __) => const _ShimmerTile(),
    );
  }

  Widget _buildError(String error, InvoicesNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.warning, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('Could not load invoices', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(error, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: notifier.refresh,
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
      ),
    );
  }

  Widget _buildEmpty() {
    return GuidedEmptyState(
      icon: PhosphorIconsRegular.receipt,
      title: 'No invoices found',
      subtitle: 'Create an invoice from a completed job',
      actionLabel: 'Create invoice',
      onAction: () => context.push('/invoices/add'),
    );
  }
}

// ---------------------------------------------------------------------------
// Invoice list tile
// ---------------------------------------------------------------------------

class _InvoiceListTile extends StatelessWidget {
  final InvoiceListItem invoice;
  final VoidCallback onTap;
  final VoidCallback? onCollect;

  const _InvoiceListTile({
    required this.invoice,
    required this.onTap,
    this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final isOverdue = invoice.isOverdue;
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOverdue ? AppColors.statusRed.withValues(alpha: 0.4) : AppColors.divider,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice.invoiceNumber,
                          style: AppTextStyles.monoMedium.copyWith(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppStatusChip(status: invoice.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(invoice.customer.fullName, style: AppTextStyles.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '${invoice.vehicle.registrationNumber} · ${invoice.serviceJob.jobNumber}',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${currencyFmt.format(invoice.totalAmount)}',
                        style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (invoice.balanceDue > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Due ₹${currencyFmt.format(invoice.balanceDue)}',
                          style: AppTextStyles.monoSmall.copyWith(
                            color: isOverdue ? AppColors.statusRed : AppColors.statusOrange,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (onCollect != null)
                        QuickActionChip(
                          icon: PhosphorIconsRegular.currencyInr,
                          label: 'Collect',
                          color: AppColors.statusGreen,
                          onTap: onCollect!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading tile
// ---------------------------------------------------------------------------

class _ShimmerTile extends StatelessWidget {
  const _ShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHigh,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 128,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
