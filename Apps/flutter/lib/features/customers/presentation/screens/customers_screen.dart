import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/customer_models.dart';
import '../providers/customers_provider.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final notifier = ref.read(customersProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(state, notifier),
            _buildSearchBar(notifier),
            const SizedBox(height: 4),
            Expanded(child: _buildList(context, state, notifier)),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeader(CustomersState state, CustomersNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customers', style: AppTextStyles.displayMedium),
                if (!state.isLoading)
                  Text(
                    '${state.customers.length} customer${state.customers.length == 1 ? '' : 's'}',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: notifier.refresh,
            icon: Icon(PhosphorIconsRegular.arrowCounterClockwise, color: AppColors.textSecondary, size: 22),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(CustomersNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
            hintText: 'Search name, phone or email…',
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

  Widget _buildList(BuildContext context, CustomersState state, CustomersNotifier notifier) {
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: 6,
        itemBuilder: (_, __) => const _ShimmerTile(),
      );
    }

    if (state.error != null && state.customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.wifiSlash, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 16),
              Text('Could not load customers', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text(state.error!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
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

    // Local instant filter against already-loaded items
    final searchText = _searchController.text.toLowerCase().trim();
    final displayCustomers = searchText.isEmpty
        ? state.customers
        : state.customers.where((c) {
            return c.fullName.toLowerCase().contains(searchText) ||
                c.phonePrimary.toLowerCase().contains(searchText) ||
                (c.email?.toLowerCase().contains(searchText) ?? false);
          }).toList();

    if (displayCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.users, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('No customers found', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text('Try a different search term', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: displayCustomers.length + (state.hasMore && searchText.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayCustomers.length) {
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
          final customer = displayCustomers[index];
          return _CustomerListTile(
            customer: customer,
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/customers/${customer.uuid}');
            },
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        context.push('/customers/add');
      },
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(PhosphorIconsRegular.plus, size: 24),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer list tile
// ---------------------------------------------------------------------------

class _CustomerListTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerListTile({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profile = customer.garageProfile;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrangeDim,
              ),
              child: Center(
                child: Text(
                  customer.initials,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.fullName,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatAmount(profile.totalSpent),
                        style: AppTextStyles.monoSmall.copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phonePrimary,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${customer.vehiclesCount} veh · ${profile.visitCount} visits'
                          '${profile.loyaltyPoints > 0 ? ' · ${profile.loyaltyPoints} pts' : ''}',
                          style: AppTextStyles.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.lastVisitedAt != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          _relativeDate(profile.lastVisitedAt!),
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(PhosphorIconsRegular.caretRight, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toInt()}';
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return DateFormat('d MMM').format(dt);
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
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
