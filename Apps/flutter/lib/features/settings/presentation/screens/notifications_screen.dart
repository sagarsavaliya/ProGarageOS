import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/notifications/notification_models.dart';
import '../../../../core/notifications/notifications_provider.dart';
import '../../../../core/widgets/api_error_view.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load();
    });
  }

  void _openNotification(StaffNotificationItem item) {
    final jobUuid = item.jobUuid;
    final invoiceUuid = item.invoiceUuid;
    if (invoiceUuid != null && invoiceUuid.isNotEmpty) {
      context.push('/invoices/$invoiceUuid');
      return;
    }
    if (jobUuid != null && jobUuid.isNotEmpty) {
      context.push('/jobs/$jobUuid');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

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
        title: Text('Notifications', style: AppTextStyles.titleMedium),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(notificationsProvider.notifier).markAllRead();
              },
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryOrange),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryOrange,
        backgroundColor: AppColors.bgSurface,
        onRefresh: () => ref.read(notificationsProvider.notifier).load(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
      );
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: ApiErrorView(
              title: 'Could not load notifications',
              message: state.errorMessage!,
              onRetry: () => ref.read(notificationsProvider.notifier).load(),
            ),
          ),
        ],
      );
    }

    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsRegular.bell, color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Job and payment alerts will appear here',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _NotificationTile(
          item: item,
          onTap: () => _openNotification(item),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final StaffNotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isRead ? AppColors.bgSurface : AppColors.bgSurface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryOrange,
                  ),
                )
              else
                const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 4),
                    Text(item.body, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
