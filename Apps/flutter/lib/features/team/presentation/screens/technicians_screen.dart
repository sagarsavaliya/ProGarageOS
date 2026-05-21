import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/api_error_view.dart';
import '../../data/models/staff_models.dart';
import '../providers/staff_provider.dart';

class TechniciansScreen extends ConsumerWidget {
  const TechniciansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffListProvider);
    final notifier = ref.read(staffListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Team', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            onPressed: notifier.refresh,
            icon: Icon(PhosphorIconsRegular.arrowCounterClockwise, color: AppColors.textSecondary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/team/add');
        },
        backgroundColor: AppColors.primaryOrange,
        child: const Icon(PhosphorIconsRegular.plus, color: Colors.white),
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, StaffListState state, StaffListNotifier notifier) {
    if (state.isLoading && state.members.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
      );
    }

    if (state.error != null && state.members.isEmpty) {
      return ApiErrorView(message: state.error!, onRetry: notifier.refresh);
    }

    if (state.members.isEmpty) {
      return ApiErrorView(
        title: 'No team members',
        message: 'Add technicians and service advisors to assign jobs.',
        icon: PhosphorIconsRegular.users,
      );
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      color: AppColors.primaryOrange,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: state.members.length,
        itemBuilder: (context, i) => _StaffTile(member: state.members[i]),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final StaffMember member;

  const _StaffTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/team/${member.uuid}');
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryOrangeDim,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryOrange),
          ),
        ),
        title: Text(member.name, style: AppTextStyles.titleSmall),
        subtitle: Text('${member.roleLabel} · ${member.openJobs} open jobs', style: AppTextStyles.bodySmall),
        trailing: Icon(
          member.isAvailable ? PhosphorIconsFill.circle : PhosphorIconsRegular.circle,
          color: member.isAvailable ? AppColors.statusGreen : AppColors.textMuted,
          size: 12,
        ),
      ),
    );
  }
}
