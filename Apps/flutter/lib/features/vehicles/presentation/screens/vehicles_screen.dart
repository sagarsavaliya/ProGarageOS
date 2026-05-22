import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../../../core/widgets/guided_empty_state.dart';
import '../../data/models/fleet_models.dart';
import '../providers/vehicles_provider.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(fleetProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fleetProvider);
    final notifier = ref.read(fleetProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary, size: 20),
        ),
        title: Text('Fleet', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            onPressed: notifier.refresh,
            icon: Icon(PhosphorIconsRegular.arrowCounterClockwise, color: AppColors.textSecondary, size: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildSearchBar(notifier),
          ),
          if (!state.isLoading && state.error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${state.total > 0 ? state.total : state.vehicles.length} vehicle${state.vehicles.length == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ),
          Expanded(child: _buildBody(context, state, notifier)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FleetNotifier notifier) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          setState(() {});
          notifier.setSearch(v);
        },
        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search reg no, make or model…',
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted),
          prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.textMuted, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(PhosphorIconsRegular.x, color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    notifier.setSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FleetState state, FleetNotifier notifier) {
    if (state.isLoading && state.vehicles.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Shimmer.fromColors(
            baseColor: AppColors.bgSurface,
            highlightColor: AppColors.bgSurface.withValues(alpha: 0.6),
            child: Container(height: 72, decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
            )),
          ),
        ),
      );
    }

    if (state.error != null && state.vehicles.isEmpty) {
      return ApiErrorView(
        title: 'Could not load fleet',
        message: state.error!,
        onRetry: notifier.refresh,
      );
    }

    if (state.vehicles.isEmpty) {
      return GuidedEmptyState(
        icon: PhosphorIconsRegular.car,
        title: 'No vehicles yet',
        subtitle: state.searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Add vehicles from a customer profile',
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: state.vehicles.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= state.vehicles.length) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
            ));
          }
          return _FleetTile(vehicle: state.vehicles[index]);
        },
      ),
    );
  }
}

class _FleetTile extends StatelessWidget {
  final FleetVehicle vehicle;

  const _FleetTile({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/vehicles/${vehicle.uuid}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrangeDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIconsRegular.car, color: AppColors.primaryOrange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.registrationNumber,
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(vehicle.makeModel, style: AppTextStyles.bodySmall),
                    if (vehicle.customer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        vehicle.customer!.name,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (vehicle.odometerReading != null)
                Text(
                  '${vehicle.odometerReading} km',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              Icon(PhosphorIconsRegular.caretRight, color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
