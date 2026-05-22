import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/phone_launcher.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/quick_action_chip.dart';
import '../../data/models/customer_models.dart';
import '../providers/customers_provider.dart';

void _leaveCustomerDetail(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/customers');
  }
}

Future<void> _launchPhone(String phone) => launchPhoneDialer(phone);

Future<void> _launchWhatsApp(String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
  final number = cleaned.startsWith('91') ? cleaned : '91$cleaned';
  final uri = Uri.parse('whatsapp://send?phone=$number');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    final fallback = Uri.parse('https://wa.me/$number');
    if (await canLaunchUrl(fallback)) await launchUrl(fallback, mode: LaunchMode.externalApplication);
  }
}

class CustomerDetailScreen extends ConsumerWidget {
  final String customerUuid;

  const CustomerDetailScreen({super.key, required this.customerUuid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDetailProvider(customerUuid));
    final notifier = ref.read(customerDetailProvider(customerUuid).notifier);
    final historyAsync = ref.watch(customerServiceHistoryProvider(customerUuid));

    return state.when(
      loading: () => _CustomerDetailShell(
        child: const _LoadingView(),
      ),
      error: (_, __) => _CustomerDetailShell(
        child: _ErrorView(onRetry: notifier.refresh),
      ),
      data: (detail) => Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: _DetailBody(
          detail: detail,
          onRefresh: notifier.refresh,
          serviceHistory: historyAsync,
        ),
      ),
    );
  }
}

class _CustomerDetailShell extends StatelessWidget {
  final Widget child;

  const _CustomerDetailShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _leaveCustomerDetail(context);
          },
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Customer', style: AppTextStyles.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.divider),
        ),
      ),
      body: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Main body
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  final CustomerDetail detail;
  final Future<void> Function() onRefresh;
  final AsyncValue<List<ServiceHistoryItem>> serviceHistory;

  const _DetailBody({
    required this.detail,
    required this.onRefresh,
    required this.serviceHistory,
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
                _buildProfileCard(context),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      QuickActionChip(
                        icon: PhosphorIconsRegular.plus,
                        label: 'New job',
                        onTap: () => context.push(
                          '/jobs/add',
                          extra: {'customerUuid': detail.uuid},
                        ),
                      ),
                      QuickActionChip(
                        icon: PhosphorIconsRegular.receipt,
                        label: 'New invoice',
                        onTap: () => context.push(
                          '/invoices/add',
                          extra: {'customerUuid': detail.uuid},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildVehiclesSection(context),
                const SizedBox(height: 16),
                _buildServiceHistorySection(context),
                const SizedBox(height: 16),
                _buildSectionHeader('Recent Jobs', '${detail.recentJobs.length}'),
                _buildRecentJobs(context),
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
          _leaveCustomerDetail(context);
        },
        icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(detail.fullName, style: AppTextStyles.titleMedium),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/customers/${detail.uuid}/edit');
          },
          icon: Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.textSecondary, size: 20),
          tooltip: 'Edit customer',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: AppColors.divider),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrangeDim,
            ),
            child: Center(
              child: Text(
                detail.initials,
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.fullName, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                _ContactRow(icon: PhosphorIconsRegular.phone, value: detail.phonePrimary),
                if (detail.email != null && detail.email!.isNotEmpty)
                  _ContactRow(icon: PhosphorIconsRegular.envelope, value: detail.email!),
                if (detail.garageProfile.internalNotes != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIconsRegular.note,
                            color: AppColors.textMuted, size: 13),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            detail.garageProfile.internalNotes!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              _ActionButton(
                icon: PhosphorIconsRegular.phone,
                color: AppColors.statusGreen,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _launchPhone(detail.phonePrimary);
                },
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: PhosphorIconsRegular.whatsappLogo,
                color: AppColors.statusBlue,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _launchWhatsApp(detail.phonePrimary);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final profile = detail.garageProfile;
    final fmt = NumberFormat('#,##,##0', 'en_IN');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(
            label: 'Total Spent',
            value: '₹${fmt.format(profile.totalSpent.toInt())}',
            icon: PhosphorIconsRegular.currencyInr,
            color: AppColors.statusGreen,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Loyalty Points',
            value: '${profile.loyaltyPoints}',
            icon: PhosphorIconsFill.star,
            color: AppColors.statusOrange,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: 'Visits',
            value: '${profile.visitCount}',
            icon: PhosphorIconsRegular.clipboardText,
            color: AppColors.statusBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleMedium),
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
      ),
    );
  }

  Widget _buildVehiclesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text('Vehicles', style: AppTextStyles.titleMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text('${detail.vehicles.length}', style: AppTextStyles.labelSmall),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push(
                    '/customers/vehicle/add',
                    extra: {
                      'customerUuid': detail.uuid,
                      'customerName': detail.fullName,
                    },
                  );
                },
                icon: Icon(PhosphorIconsRegular.plus, size: 16, color: AppColors.primaryOrange),
                label: Text('Add', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryOrange)),
              ),
            ],
          ),
        ),
        _buildVehiclesList(context),
      ],
    );
  }

  Widget _buildVehiclesList(BuildContext context) {
    if (detail.vehicles.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(child: Text('No vehicles registered', style: AppTextStyles.bodySmall)),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: detail.vehicles.length,
        itemBuilder: (context, i) => _VehicleCard(
          vehicle: detail.vehicles[i],
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              '/vehicles/${detail.vehicles[i].uuid}',
              extra: {'customer': detail.uuid},
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceHistorySection(BuildContext context) {
    return serviceHistory.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Service History', '…'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(color: AppColors.primaryOrange, minHeight: 2),
          ),
        ],
      ),
      error: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Service History', '—'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Could not load service history', style: AppTextStyles.bodySmall),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Service History', '0'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(child: Text('No service history yet', style: AppTextStyles.bodySmall)),
              ),
            ],
          );
        }

        final fmt = NumberFormat('#,##,##0', 'en_IN');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Service History', '${items.length}'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: items.take(10).toList().asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == items.take(10).length - 1;
                  final route = item.type == 'invoice'
                      ? '/invoices/${item.uuid}'
                      : '/jobs/${item.uuid}';

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(route);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                item.type == 'invoice'
                                    ? PhosphorIconsRegular.receipt
                                    : PhosphorIconsRegular.clipboardText,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, style: AppTextStyles.titleSmall),
                                    if (item.subtitle != null && item.subtitle!.isNotEmpty)
                                      Text(item.subtitle!, style: AppTextStyles.labelSmall),
                                  ],
                                ),
                              ),
                              if (item.amount != null)
                                Text(
                                  '₹${fmt.format(item.amount!.toInt())}',
                                  style: AppTextStyles.monoSmall,
                                ),
                              const SizedBox(width: 6),
                              Icon(PhosphorIconsRegular.caretRight,
                                  color: AppColors.textMuted, size: 16),
                            ],
                          ),
                        ),
                      ),
                      if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentJobs(BuildContext context) {
    if (detail.recentJobs.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(child: Text('No recent jobs yet', style: AppTextStyles.bodySmall)),
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
        children: detail.recentJobs.asMap().entries.map((entry) {
          final job = entry.value;
          final isLast = entry.key == detail.recentJobs.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/jobs/${job.uuid}');
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Text(job.jobNumber, style: AppTextStyles.monoMedium),
                      const Spacer(),
                      AppStatusChip(status: job.status),
                      const SizedBox(width: 8),
                      if (job.createdAt != null)
                        Text(
                          DateFormat('d MMM yy').format(job.createdAt!.toLocal()),
                          style: AppTextStyles.labelSmall,
                        ),
                      const SizedBox(width: 6),
                      Icon(PhosphorIconsRegular.caretRight,
                          color: AppColors.textMuted, size: 16),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, color: AppColors.divider, indent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle card (horizontal scroll)
// ---------------------------------------------------------------------------

class _VehicleCard extends StatelessWidget {
  final CustomerVehicleSummary vehicle;
  final VoidCallback onTap;

  const _VehicleCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(PhosphorIconsRegular.car,
                    color: AppColors.primaryOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vehicle.registrationNumber,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              vehicle.makeModel,
              style: AppTextStyles.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    vehicle.fuelType.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 9, letterSpacing: 0.6),
                  ),
                ),
                const Spacer(),
                if (vehicle.odometerReading != null) ...[
                  Icon(PhosphorIconsRegular.gauge, color: AppColors.textMuted, size: 11),
                  const SizedBox(width: 3),
                  Text(
                    '${(vehicle.odometerReading! / 1000).toStringAsFixed(1)}k km',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable sub-widgets
// ---------------------------------------------------------------------------

class _ContactRow extends StatelessWidget {
  final PhosphorIconData icon;
  final String value;

  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 13),
          const SizedBox(width: 5),
          Text(value, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final PhosphorIconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final PhosphorIconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.titleSmall),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading + error
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
          Text('Could not load customer', style: AppTextStyles.titleMedium),
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

