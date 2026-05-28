import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../inventory/data/inventory_repository.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardProvider);
    final lowStockAsync = ref.watch(_lowStockProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Reports', style: AppTextStyles.titleMedium),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(_lowStockProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            dashState.data.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
              error: (e, _) => ApiErrorView(
                title: 'Could not load KPIs',
                message: e.toString(),
                onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
              ),
              data: (summary) => _KpiGrid(summary: summary),
            ),
            const SizedBox(height: 16),
            Text('Low stock items', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            lowStockAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
              ),
              error: (e, _) => Text('Could not load inventory alerts', style: AppTextStyles.bodySmall),
              data: (items) {
                if (items.isEmpty) {
                  return Text('No low stock alerts', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted));
                }
                return Column(
                  children: items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name, style: AppTextStyles.bodyMedium),
                          subtitle: Text('Stock ${item.stockQuantity} · threshold ${item.minimumStockLevel}',
                              style: AppTextStyles.labelSmall),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Quick links', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            _QuickLink(label: 'Jobs', onTap: () => context.go('/jobs')),
            _QuickLink(label: 'Billing', onTap: () => context.go('/invoices')),
            _QuickLink(label: 'Appointments', onTap: () => context.go('/appointments')),
            _QuickLink(label: 'Audit log', onTap: () => context.push('/audit')),
          ],
        ),
      ),
    );
  }
}

final _lowStockProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  final result = await repo.fetchItems(page: 1, lowStockOnly: true);
  return result.data;
});

class _KpiGrid extends StatelessWidget {
  final dynamic summary;

  const _KpiGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _KpiCard(label: 'Jobs today', value: '${summary.jobsToday}'),
        _KpiCard(label: 'Revenue', value: summary.revenueDisplay),
        _KpiCard(label: 'Pending approvals', value: '${summary.pendingApprovals}'),
        _KpiCard(label: 'Active jobs', value: '${summary.activeJobs.length}'),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;

  const _KpiCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryOrange)),
      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
