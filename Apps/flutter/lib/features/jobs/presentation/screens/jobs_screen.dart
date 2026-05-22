import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/guided_empty_state.dart';
import '../../../../core/widgets/quick_action_chip.dart';
import '../../data/models/job_models.dart';
import '../providers/jobs_provider.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobsProvider);
    final notifier = ref.read(jobsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state, notifier),
            _buildSearchBar(notifier),
            _buildFilterTabs(notifier),
            Expanded(
              child: _buildJobsList(context, state, notifier),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeader(BuildContext context, JobsState state, JobsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jobs', style: AppTextStyles.displayMedium),
                if (!state.isLoading)
                  Text(
                    '${state.jobs.length} job${state.jobs.length == 1 ? '' : 's'}${state.statusFilter != null ? ' · filtered' : ''}',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => notifier.refresh(),
            icon: Icon(PhosphorIconsRegular.arrowCounterClockwise, color: AppColors.textSecondary, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(JobsNotifier notifier) {
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
            hintText: 'Search job #, customer or plate…',
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
            prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.textMuted, size: 20),
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

  Widget _buildFilterTabs(JobsNotifier notifier) {
    return AppFilterChipsBar(
      children: [
        for (var i = 0; i < jobFilterTabLabels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          AppFilterChip(
            label: jobFilterTabLabels[i],
            isSelected: _selectedTabIndex == i,
            onTap: () {
              setState(() => _selectedTabIndex = i);
              notifier.setStatusFilter(jobFilterTabs[i]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildJobsList(BuildContext context, JobsState state, JobsNotifier notifier) {
    if (state.isLoading) {
      return _buildShimmerList();
    }

    if (state.error != null && state.jobs.isEmpty) {
      return _buildError(state.error!, notifier);
    }

    // Local instant filter against already-loaded items
    final searchText = _searchController.text.toLowerCase().trim();
    final displayJobs = searchText.isEmpty
        ? state.jobs
        : state.jobs.where((j) {
            return j.jobNumber.toLowerCase().contains(searchText) ||
                j.customer.name.toLowerCase().contains(searchText) ||
                j.vehicle.registrationNumber.toLowerCase().contains(searchText);
          }).toList();

    if (displayJobs.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: displayJobs.length + (state.hasMore && searchText.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayJobs.length) {
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
          return _JobListTile(
            job: displayJobs[index],
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/jobs/${displayJobs[index].uuid}');
            },
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

  Widget _buildError(String error, JobsNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.wifiSlash, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('Could not load jobs', style: AppTextStyles.titleMedium),
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
      icon: PhosphorIconsRegular.clipboardText,
      title: 'No jobs found',
      subtitle: 'Try a different filter or create a new job',
      actionLabel: 'New job',
      onAction: () => context.push('/jobs/add'),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        context.push('/jobs/add');
      },
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(PhosphorIconsRegular.plus, size: 24),
    );
  }
}

// ---------------------------------------------------------------------------
// Job list tile
// ---------------------------------------------------------------------------

class _JobListTile extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _JobListTile({required this.job, required this.onTap});

  Future<void> _callCustomer() async {
    final phone = job.customer.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final showInspect = job.status == JobStatus.intakeInspection;

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
              border: Border.all(color: AppColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(job.jobNumber, style: AppTextStyles.monoMedium)),
                      if (job.priority != JobPriority.normal) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: job.priority == JobPriority.vip
                                ? AppColors.statusPurpleBg
                                : AppColors.statusRedBg,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            job.priority.label.toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: job.priority == JobPriority.vip
                                  ? AppColors.statusPurple
                                  : AppColors.statusRed,
                            ),
                          ),
                        ),
                      ],
                      AppStatusChip(status: job.status.apiValue),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(PhosphorIconsRegular.car, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${job.vehicle.registrationNumber} · ${job.customer.name}',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (job.estimatedAmount > 0)
                        Text(
                          '₹${_formatAmount(job.estimatedAmount)}',
                          style: AppTextStyles.monoSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (job.customer.phone.isNotEmpty)
                        QuickActionChip(
                          icon: PhosphorIconsRegular.phone,
                          label: 'Call',
                          color: AppColors.statusGreen,
                          onTap: _callCustomer,
                        ),
                      if (showInspect) ...[
                        const SizedBox(width: 6),
                        QuickActionChip(
                          icon: PhosphorIconsRegular.clipboardText,
                          label: 'Inspect',
                          onTap: () => context.push('/jobs/${job.uuid}/inspection'),
                        ),
                      ],
                      const Spacer(),
                      if (job.primaryTechnician != null)
                        Text(
                          job.primaryTechnician!.name.split(' ').first,
                          style: AppTextStyles.labelSmall,
                        ),
                      const SizedBox(width: 4),
                      Icon(PhosphorIconsRegular.caretRight, color: AppColors.textMuted, size: 16),
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

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toInt().toString();
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
        height: 156,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
