import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/notifications/notification_models.dart';
import '../../../../core/notifications/notifications_provider.dart';
import '../../../../core/notifications/fcm_service.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/dashboard_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _notifPanelOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load();
      ref.read(fcmServiceProvider).initialize().then((_) {
        ref.read(fcmServiceProvider).registerTokenIfAvailable();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // App bar
                  _AppBar(
                    onNotifTap: () {
                      if (!_notifPanelOpen) {
                        ref.read(notificationsProvider.notifier).load();
                      }
                      setState(() => _notifPanelOpen = !_notifPanelOpen);
                    },
                    onSettingsTap: () => context.push('/settings'),
                    hasUnread: unreadCount > 0,
                    unreadCount: unreadCount,
                  ),
                  // Content
                  Expanded(
                    child: dashState.data.when(
                      loading: () => const _DashboardShimmer(),
                      error: (e, _) => _ErrorView(onRetry: notifier.refresh),
                      data: (summary) => RefreshIndicator(
                        color: AppColors.primaryOrange,
                        backgroundColor: AppColors.bgSurface,
                        onRefresh: notifier.refresh,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.only(top: AppSizes.lg),
                              sliver: SliverToBoxAdapter(
                                child: _PeriodSelector(
                                  selected: dashState.period,
                                  onSelect: notifier.setPeriod,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _KpiRow(summary: summary),
                            ),
                            SliverToBoxAdapter(
                              child: _RevenueChartCard(
                                points: summary.weeklyRevenue,
                                totalDisplay: summary.revenueDisplay,
                                changePercent: summary.revenueChangePercent,
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: _SectionHeader(title: 'Service Bays', actionLabel: 'Manage'),
                            ),
                            SliverToBoxAdapter(
                              child: _BayGrid(bays: summary.serviceBays),
                            ),
                            const SliverToBoxAdapter(
                              child: _SectionHeader(title: 'Active Jobs', actionLabel: 'View all'),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                              sliver: SliverList.builder(
                                itemCount: summary.activeJobs.length,
                                itemBuilder: (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                                  child: _JobCard(job: summary.activeJobs[i]),
                                ),
                              ),
                            ),
                            const SliverPadding(
                              padding: EdgeInsets.only(bottom: 88),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Notification panel overlay
              AnimatedSlide(
                offset: _notifPanelOpen ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: AnimatedOpacity(
                  opacity: _notifPanelOpen ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _NotifPanel(
                    onDismiss: () => setState(() => _notifPanelOpen = false),
                    onViewAll: () {
                      setState(() => _notifPanelOpen = false);
                      context.push('/notifications');
                    },
                    onMarkAllRead: () {
                      ref.read(notificationsProvider.notifier).markAllRead();
                    },
                    onNotificationTap: (item) {
                      setState(() => _notifPanelOpen = false);
                      final jobUuid = item.jobUuid;
                      if (jobUuid != null && jobUuid.isNotEmpty) {
                        context.push('/jobs/$jobUuid');
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// App bar
// ---------------------------------------------------------------------------

class _AppBar extends StatelessWidget {
  final VoidCallback onNotifTap;
  final VoidCallback onSettingsTap;
  final bool hasUnread;
  final int unreadCount;

  const _AppBar({
    required this.onNotifTap,
    required this.onSettingsTap,
    required this.hasUnread,
    this.unreadCount = 0,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateStr() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]} · ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.appBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${_greeting()}, ',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.01 * 15,
                          height: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Rajesh',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.01 * 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _dateStr().toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.06 * 10),
                ),
              ],
            ),
          ),
          // Notification bell
          GestureDetector(
            onTap: onNotifTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Icon(PhosphorIconsRegular.bell, size: 20, color: AppColors.textSecondary),
                ),
                if (hasUnread)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.statusRed,
                        border: Border.all(color: AppColors.bgSurface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.statusBlueBg,
                border: Border.all(color: AppColors.statusBlue.withOpacity(0.30), width: 0.5),
              ),
              alignment: Alignment.center,
              child: Icon(
                PhosphorIconsRegular.gear,
                size: 16,
                color: AppColors.statusBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period selector chips
// ---------------------------------------------------------------------------

class _PeriodSelector extends StatelessWidget {
  final DashboardPeriod selected;
  final void Function(DashboardPeriod) onSelect;

  const _PeriodSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        children: DashboardPeriod.values.map((p) {
          final isActive = p == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect(p);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryOrange : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: isActive ? AppColors.primaryOrange : AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI cards row
// ---------------------------------------------------------------------------

class _KpiRow extends StatelessWidget {
  final DashboardSummary summary;

  const _KpiRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.md),
        children: [
          _KpiCard(
            label: 'Jobs Today',
            value: '${summary.jobsToday}',
            delta: '↑ 3 from yesterday',
            deltaType: _DeltaType.up,
          ),
          _KpiCard(
            label: 'Revenue MTD',
            value: summary.revenueDisplay,
            delta: '↑ ${summary.revenueChangePercent.toStringAsFixed(1)}% this month',
            deltaType: summary.revenueChangePercent >= 0 ? _DeltaType.up : _DeltaType.down,
            isMono: true,
          ),
          _KpiCard(
            label: 'Pending',
            value: '${summary.pendingApprovals}',
            delta: 'Estimates & approvals',
            deltaType: _DeltaType.neutral,
            variant: _KpiVariant.warn,
          ),
          _KpiCard(
            label: 'Low Stock',
            value: '${summary.lowStockItems} items',
            delta: 'Reorder needed',
            deltaType: _DeltaType.neutral,
            variant: _KpiVariant.danger,
          ),
        ],
      ),
    );
  }
}

enum _DeltaType { up, down, neutral }
enum _KpiVariant { normal, warn, danger }

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final _DeltaType deltaType;
  final _KpiVariant variant;
  final bool isMono;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaType,
    this.variant = _KpiVariant.normal,
    this.isMono = false,
  });

  Color get _bgColor {
    switch (variant) {
      case _KpiVariant.warn:
        return const Color(0xFF1A1200);
      case _KpiVariant.danger:
        return const Color(0xFF1A0000);
      case _KpiVariant.normal:
        return AppColors.bgSurface;
    }
  }

  Color get _labelColor {
    switch (variant) {
      case _KpiVariant.warn:
        return const Color(0xFFF0A018);
      case _KpiVariant.danger:
        return AppColors.statusRed;
      case _KpiVariant.normal:
        return AppColors.textMuted;
    }
  }

  Color get _valueColor {
    switch (variant) {
      case _KpiVariant.warn:
        return const Color(0xFFF0A018);
      case _KpiVariant.danger:
        return AppColors.statusRed;
      case _KpiVariant.normal:
        return AppColors.textPrimary;
    }
  }

  Color get _deltaColor {
    switch (deltaType) {
      case _DeltaType.up:
        return AppColors.statusGreen;
      case _DeltaType.down:
        return AppColors.statusRed;
      case _DeltaType.neutral:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.07 * 10,
              color: _labelColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: isMono
                ? GoogleFonts.dmMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: _valueColor,
                    letterSpacing: -0.02 * 18,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )
                : GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: _valueColor,
                    letterSpacing: -0.025 * 22,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const Spacer(),
          Text(
            delta,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _deltaColor,
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Revenue chart card
// ---------------------------------------------------------------------------

class _RevenueChartCard extends StatelessWidget {
  final List<RevenuePoint> points;
  final String totalDisplay;
  final double changePercent;

  const _RevenueChartCard({
    required this.points,
    required this.totalDisplay,
    required this.changePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REVENUE · 7 DAYS',
                style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.08 * 10),
              ),
              Text('Full report →',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryOrange)),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily revenue',
                          style: AppTextStyles.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '7-day trend',
                          style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.04 * 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        totalDisplay,
                        style: GoogleFonts.dmMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.01 * 18,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '↑ ${changePercent.toStringAsFixed(1)}% vs last week',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.statusGreen),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (points.isNotEmpty) _RevenueSparkline(points: points),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.xl),
      ],
    );
  }
}

class _RevenueSparkline extends StatelessWidget {
  final List<RevenuePoint> points;

  const _RevenueSparkline({required this.points});

  @override
  Widget build(BuildContext context) {
    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.amount);
    }).toList();

    final maxY = points.map((p) => p.amount).reduce((a, b) => a > b ? a : b) * 1.15;

    return SizedBox(
      height: 80,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 16,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  final isLast = i == points.length - 1;
                  return Text(
                    points[i].dayLabel,
                    style: GoogleFonts.dmMono(
                      fontSize: 8,
                      color: isLast ? AppColors.primaryOrange : AppColors.textMuted,
                      fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.primaryOrange,
              barWidth: 1.8,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  final isLast = index == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 4 : 2.5,
                    color: isLast ? AppColors.primaryOrange : AppColors.primaryOrange.withOpacity(0.6),
                    strokeWidth: isLast ? 0 : 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryOrange.withOpacity(0.18),
                    AppColors.primaryOrange.withOpacity(0.01),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.bgElevated,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final amount = spot.y;
                  final label = amount >= 100000
                      ? '₹${(amount / 100000).toStringAsFixed(1)}L'
                      : '₹${(amount / 1000).toStringAsFixed(0)}K';
                  return LineTooltipItem(
                    label,
                    GoogleFonts.dmMono(
                      fontSize: 11,
                      color: AppColors.primaryOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;

  const _SectionHeader({required this.title, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.08 * 10)),
          Text(
            '$actionLabel →',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryOrange),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bay grid
// ---------------------------------------------------------------------------

class _BayGrid extends StatelessWidget {
  final List<ServiceBay> bays;

  const _BayGrid({required this.bays});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.xl),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
        ),
        itemCount: bays.length,
        itemBuilder: (ctx, i) => _BayCard(bay: bays[i]),
      ),
    );
  }
}

class _BayCard extends StatelessWidget {
  final ServiceBay bay;

  const _BayCard({required this.bay});

  ({Color text, Color bg, Color dot, String label}) get _statusChip {
    switch (bay.status) {
      case BayStatus.occupied:
        return (
          text: AppColors.statusBlue,
          bg: AppColors.statusBlueBg,
          dot: AppColors.statusBlue,
          label: 'Occupied',
        );
      case BayStatus.available:
        return (
          text: AppColors.statusGreen,
          bg: AppColors.statusGreenBg,
          dot: AppColors.statusGreen,
          label: 'Available',
        );
      case BayStatus.maintenance:
        return (
          text: AppColors.statusOrange,
          bg: AppColors.statusOrangeBg,
          dot: AppColors.statusOrange,
          label: 'Maint.',
        );
    }
  }

  Color get _progressColor {
    switch (bay.status) {
      case BayStatus.occupied:
        return AppColors.statusBlue;
      case BayStatus.maintenance:
        return AppColors.statusOrange;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chip = _statusChip;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bay.name, style: AppTextStyles.titleSmall),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: chip.bg,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: chip.dot),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chip.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: chip.text,
                              letterSpacing: 0.03 * 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(bay.type, style: AppTextStyles.bodyMedium.copyWith(fontSize: 10)),
                const SizedBox(height: 8),
                if (bay.status == BayStatus.occupied) ...[
                  Text(
                    bay.vehiclePlate ?? '',
                    style: GoogleFonts.dmMono(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.02 * 11,
                    ),
                  ),
                  Text(
                    bay.vehicleModel ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else if (bay.status == BayStatus.available) ...[
                  Text(
                    'Ready for vehicle',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else ...[
                  Text(
                    'ETA ~2 hours',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 11,
                      color: AppColors.statusOrange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Progress bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 3,
              color: AppColors.bgElevated,
              child: FractionallySizedBox(
                widthFactor: bay.progressPercent.clamp(0, 1),
                alignment: Alignment.centerLeft,
                child: Container(color: _progressColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Job cards
// ---------------------------------------------------------------------------

class _JobCard extends StatelessWidget {
  final ActiveJob job;

  const _JobCard({required this.job});

  Color _progressColor(String status) {
    switch (status) {
      case 'in_progress':
        return AppColors.statusBlue;
      case 'estimate_pending':
        return const Color(0xFFF0A018);
      case 'qc_pending':
        return AppColors.statusTeal;
      case 'ready_for_delivery':
      case 'ready_for_collection':
        return AppColors.statusGreen;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/jobs/${job.uuid}');
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        job.jobNumber,
                        style: GoogleFonts.dmMono(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.02 * 12,
                        ),
                      ),
                      AppStatusChip(status: job.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(job.customerName, style: AppTextStyles.titleSmall),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${job.vehicleDescription} · ',
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
                        ),
                        TextSpan(
                          text: job.vehiclePlate,
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.statusTealBg,
                              border: Border.all(
                                color: AppColors.statusTeal.withOpacity(0.25),
                                width: 0.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              job.techInitials,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColors.statusTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(job.techName, style: AppTextStyles.bodyMedium.copyWith(fontSize: 11)),
                        ],
                      ),
                      Text(
                        job.etaDisplay,
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: job.status == 'ready_for_delivery' || job.status == 'ready_for_collection'
                              ? AppColors.statusTeal
                              : AppColors.textMuted,
                          fontWeight: job.status == 'ready_for_delivery' || job.status == 'ready_for_collection'
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Progress bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2.5,
                color: AppColors.bgElevated,
                child: FractionallySizedBox(
                  widthFactor: job.progressPercent.clamp(0, 1),
                  alignment: Alignment.centerLeft,
                  child: Container(color: _progressColor(job.status)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification panel
// ---------------------------------------------------------------------------

class _NotifPanel extends ConsumerWidget {
  final VoidCallback onDismiss;
  final VoidCallback onMarkAllRead;
  final VoidCallback onViewAll;
  final void Function(StaffNotificationItem item) onNotificationTap;

  const _NotifPanel({
    required this.onDismiss,
    required this.onMarkAllRead,
    required this.onViewAll,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: AppTextStyles.titleSmall),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onMarkAllRead();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Mark all read',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryOrange),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (notifState.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
              ),
            )
          else if (notifState.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No notifications yet', style: AppTextStyles.bodySmall),
            )
          else
            ...notifState.items.take(8).map((item) {
              return _NotifItem(
                dotColor: _dotColorForEvent(item.eventCode),
                title: item.title,
                message: item.body,
                time: _timeAgo(item.createdAt),
                isUnread: !item.isRead,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onNotificationTap(item);
                },
              );
            }),
          if (notifState.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View all notifications',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryOrange),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _dotColorForEvent(String code) {
    if (code.contains('stock') || code.contains('low')) return AppColors.statusRed;
    if (code.contains('ready') || code.contains('delivery')) return AppColors.statusTeal;
    if (code.contains('estimate')) return AppColors.statusOrange;
    return AppColors.primaryOrange;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays}d ago';
  }
}

class _NotifItem extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final VoidCallback onTap;

  const _NotifItem({
    required this.dotColor,
    required this.title,
    required this.message,
    required this.time,
    this.isUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.primaryOrangeDim.withOpacity(0.35) : null,
          border: const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(message, style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(time, style: AppTextStyles.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer loading
// ---------------------------------------------------------------------------

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        children: [
          // Period row shimmer
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 80,
                height: 32,
                margin: const EdgeInsets.only(right: AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          // KPI shimmer
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  height: 82,
                  margin: EdgeInsets.only(right: i < 3 ? 10.0 : 0),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          // Chart shimmer
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsRegular.wifiSlash, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSizes.lg),
          Text('Unable to load dashboard', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSizes.sm),
          Text('Check your connection and retry.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSizes.xxl),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryOrange)),
          ),
        ],
      ),
    );
  }
}


