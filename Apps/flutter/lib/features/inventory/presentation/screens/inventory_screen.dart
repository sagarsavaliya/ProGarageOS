import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/guided_empty_state.dart';
import '../../../../core/widgets/quick_action_chip.dart';
import '../../data/models/inventory_models.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/inventory/add');
        },
        backgroundColor: AppColors.primaryOrange,
        elevation: 4,
        child: const Icon(PhosphorIconsRegular.plus, color: Colors.white, size: 24),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(state, notifier),
            _buildSearchBar(notifier),
            _buildFilterRow(state, notifier),
            Expanded(child: _buildList(context, state, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(InventoryState state, InventoryNotifier notifier) {
    final lowCount = state.items
        .where((i) => i.isLowStock || i.isOutOfStock)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          // Title + count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inventory', style: AppTextStyles.displayMedium),
                if (!state.isLoading)
                  Text(
                    '${state.items.length} parts',
                    style: AppTextStyles.monoSmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          // Low-stock alert badge
          if (!state.isLoading && lowCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusRedBg,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.statusRed.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsFill.warning,
                    color: AppColors.statusRed,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$lowCount low',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.statusRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Refresh
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

  Widget _buildSearchBar(InventoryNotifier notifier) {
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
            hintText: 'Search parts, SKU, category…',
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

  Widget _buildFilterRow(InventoryState state, InventoryNotifier notifier) {
    final categoriesAsync = ref.watch(partsCategoriesProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (cats) => cats,
      orElse: () => <PartsCategory>[],
    );

    return AppFilterChipsBar(
      children: [
        AppFilterChip(
          label: 'All',
          isSelected: !state.showLowStockOnly && state.selectedCategoryId == null,
          onTap: () {
            if (state.showLowStockOnly) notifier.toggleLowStockFilter();
            notifier.setCategory(null);
          },
        ),
        const SizedBox(width: 8),
        AppFilterChip(
          label: 'Low Stock',
          isSelected: state.showLowStockOnly,
          activeColor: AppColors.statusRed,
          onTap: notifier.toggleLowStockFilter,
        ),
        for (final cat in categories) ...[
          const SizedBox(width: 8),
          AppFilterChip(
            label: cat.name,
            isSelected: state.selectedCategoryId == cat.id,
            onTap: () {
              notifier.setCategory(
                state.selectedCategoryId == cat.id ? null : cat.id,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    InventoryState state,
    InventoryNotifier notifier,
  ) {
    if (state.isLoading) return _buildShimmerList();
    if (state.errorMessage != null && state.items.isEmpty) {
      return _buildError(state.errorMessage!, notifier);
    }

    // Local instant filter against already-loaded items
    final searchText = _searchController.text.toLowerCase().trim();
    final displayItems = searchText.isEmpty
        ? state.items
        : state.items.where((item) {
            return item.name.toLowerCase().contains(searchText) ||
                item.sku.toLowerCase().contains(searchText) ||
                item.category.name.toLowerCase().contains(searchText);
          }).toList();

    if (displayItems.isEmpty) {
      return _buildEmpty(state.showLowStockOnly);
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      backgroundColor: AppColors.bgSurface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        itemCount: displayItems.length + (state.hasMore && searchText.isEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayItems.length) {
            notifier.loadMore();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHigh,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }
          return _InventoryItemTile(
            item: displayItems[index],
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/inventory/${displayItems[index].uuid}');
            },
            onAdjust: () {
              HapticFeedback.lightImpact();
              context.push('/inventory/${displayItems[index].uuid}');
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: 10,
      itemBuilder: (_, __) => const _ShimmerTile(),
    );
  }

  Widget _buildError(String error, InventoryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsRegular.warning, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('Could not load inventory', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(error, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.ghost,
              onPressed: notifier.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isLowStockFilter) {
    if (isLowStockFilter) {
      return const GuidedEmptyState(
        icon: PhosphorIconsFill.checkCircle,
        title: 'Stock levels are healthy',
        subtitle: 'All items are above minimum threshold',
      );
    }
    return GuidedEmptyState(
      icon: PhosphorIconsRegular.package,
      title: 'No parts found',
      subtitle: 'Add your first part to track inventory',
      actionLabel: 'Add part',
      onAction: () => context.push('/inventory/add'),
    );
  }
}

// ---------------------------------------------------------------------------
// Inventory item tile
// ---------------------------------------------------------------------------

class _InventoryItemTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback onAdjust;

  const _InventoryItemTile({
    required this.item,
    required this.onTap,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');
    final (stockColor, statusLabel) = _stockColorAndLabel(item.stockStatus);

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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: stockColor, width: 3)),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AppTextStyles.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(
                          '${item.category.name} · ${item.sku}',
                          style: AppTextStyles.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${currencyFmt.format(item.sellingPrice)} · cost ₹${currencyFmt.format(item.costPrice)}',
                          style: AppTextStyles.monoSmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.stockQuantity}',
                        style: AppTextStyles.monoLarge.copyWith(
                          color: stockColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      Text(item.unit, style: AppTextStyles.labelSmall),
                      if (statusLabel != null) ...[
                        const SizedBox(height: 4),
                        _StockStatusBadge(label: statusLabel, color: stockColor),
                      ],
                      const SizedBox(height: 6),
                      QuickActionChip(
                        icon: PhosphorIconsRegular.pencilSimple,
                        label: 'Adjust',
                        onTap: onAdjust,
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

  (Color, String?) _stockColorAndLabel(StockStatus status) {
    switch (status) {
      case StockStatus.outOfStock:
        return (AppColors.statusRed, 'OUT');
      case StockStatus.lowStock:
        return (AppColors.statusOrange, 'LOW');
      case StockStatus.adequate:
        return (AppColors.statusGreen, 'OK');
      case StockStatus.wellStocked:
        return (AppColors.statusTeal, null);
    }
  }
}

// ---------------------------------------------------------------------------
// Stock status badge pill
// ---------------------------------------------------------------------------

class _StockStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StockStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontSize: 8,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
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
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
