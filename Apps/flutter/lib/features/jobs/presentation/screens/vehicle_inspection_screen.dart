import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/config/env.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/customer_signature_card.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/inspection_models.dart';
import '../providers/jobs_provider.dart';
import '../providers/vehicle_inspection_provider.dart';
import '../widgets/vehicle_damage_map.dart';

class VehicleInspectionScreen extends ConsumerStatefulWidget {
  final String jobUuid;
  final String phase;

  const VehicleInspectionScreen({
    super.key,
    required this.jobUuid,
    this.phase = 'intake',
  });

  bool get isDelivery => phase == 'delivery';

  @override
  ConsumerState<VehicleInspectionScreen> createState() => _VehicleInspectionScreenState();
}

class _VehicleInspectionScreenState extends ConsumerState<VehicleInspectionScreen> {
  final _notesController = TextEditingController();
  bool _notesHydrated = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = InspectionScope(jobUuid: widget.jobUuid, phase: widget.phase);
    final inspection = ref.watch(vehicleInspectionProvider(scope));
    final notifier = ref.read(vehicleInspectionProvider(scope).notifier);
    final jobUuid = widget.jobUuid;
    final detailAsync = ref.watch(jobDetailProvider(jobUuid));

    if (!_notesHydrated && !inspection.isLoading) {
      _notesController.text = inspection.notes;
      _notesHydrated = true;
    }

    if (inspection.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    final detail = detailAsync.valueOrNull;
    final jobNumber = detail?.jobNumber ?? 'Job';
    final vehicleLabel = detail != null
        ? '${detail.vehicle.makeModel} · ${detail.vehicle.registrationNumber}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: _InspectionBody(
        jobNumber: jobNumber,
        vehicleLabel: vehicleLabel,
        isDelivery: widget.isDelivery,
        state: inspection,
        onSetCondition: notifier.setCondition,
        onCycleDamage: notifier.cycleDamage,
        onClearDamage: notifier.clearDamage,
        notesController: _notesController,
        onNotesChanged: notifier.setNotes,
        onAcknowledged: notifier.setAcknowledged,
        onCapturePhoto: notifier.capturePhoto,
        onPickGallery: notifier.pickPhotoFromGallery,
        onSubmit: () async {
          notifier.setNotes(_notesController.text);
          final ok = await notifier.submit();
          if (ok && context.mounted) {
            ref.invalidate(jobDetailProvider(jobUuid));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.isDelivery
                      ? 'Delivery inspection saved · $jobNumber'
                      : 'Intake saved · $jobNumber moved to estimate',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: AppColors.statusGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
            ref.invalidate(dashboardProvider);
            context.pop();
          }
        },
      ),
    );
  }
}

class _InspectionBody extends StatefulWidget {
  final String jobNumber;
  final String vehicleLabel;
  final bool isDelivery;
  final VehicleInspectionState state;
  final void Function(String, InspectionCondition) onSetCondition;
  final void Function(String) onCycleDamage;
  final VoidCallback onClearDamage;
  final TextEditingController notesController;
  final void Function(String) onNotesChanged;
  final void Function(bool) onAcknowledged;
  final void Function(int) onCapturePhoto;
  final void Function(int) onPickGallery;
  final VoidCallback onSubmit;

  const _InspectionBody({
    required this.jobNumber,
    required this.vehicleLabel,
    required this.isDelivery,
    required this.state,
    required this.onSetCondition,
    required this.onCycleDamage,
    required this.onClearDamage,
    required this.notesController,
    required this.onNotesChanged,
    required this.onAcknowledged,
    required this.onCapturePhoto,
    required this.onPickGallery,
    required this.onSubmit,
  });

  @override
  State<_InspectionBody> createState() => _InspectionBodyState();
}

class _InspectionBodyState extends State<_InspectionBody> {
  bool _scrollLocked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
      physics: _scrollLocked
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.bgSurface,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.caretLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isDelivery ? 'Delivery Inspection' : 'Intake Inspection',
                style: AppTextStyles.titleMedium,
              ),
              if (widget.vehicleLabel.isNotEmpty)
                Text(widget.vehicleLabel, style: AppTextStyles.bodySmall),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.state.completedChecklistCount / widget.state.totalChecklistCount,
                        minHeight: 4,
                        backgroundColor: AppColors.bgElevated,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.state.completedChecklistCount}/${widget.state.totalChecklistCount}',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PhotosCard(
                  photos: widget.state.photos,
                  onCapture: widget.onCapturePhoto,
                  onGallery: widget.onPickGallery,
                ),
                const SizedBox(height: 12),
                _ChecklistCard(
                  items: widget.state.checklistItems,
                  conditions: widget.state.conditions,
                  onSetCondition: widget.onSetCondition,
                ),
                const SizedBox(height: 12),
                VehicleDamageMap(
                  damageZones: widget.state.damageZones,
                  onZoneTap: widget.onCycleDamage,
                  onClearAll: widget.state.damageZones.isEmpty ? null : widget.onClearDamage,
                ),
                const SizedBox(height: 12),
                _NotesCard(
                  controller: widget.notesController,
                  onChanged: widget.onNotesChanged,
                ),
                const SizedBox(height: 12),
                CustomerSignatureCard(
                  isDelivery: widget.isDelivery,
                  signed: widget.state.customerAcknowledged,
                  onSignedChanged: widget.onAcknowledged,
                  onSigningActiveChanged: (active) {
                    if (_scrollLocked != active) {
                      setState(() => _scrollLocked = active);
                    }
                  },
                ),
                if (widget.state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.state.errorMessage!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.statusRed),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: widget.state.canSubmit
                ? () {
                    HapticFeedback.mediumImpact();
                    widget.onSubmit();
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: widget.state.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    widget.state.canSubmit
                        ? (widget.isDelivery ? 'Submit' : 'Save & send for estimate')
                        : _submitHint(widget.state),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  String _submitHint(VehicleInspectionState s) {
    if (s.hasUploading) return 'Uploading photos…';
    if (s.photosRequired && !s.allPhotosReady) return 'Add vehicle photos (optional at delivery)';
    if (s.completedChecklistCount < s.totalChecklistCount) return 'Complete checklist';
    if (!s.customerAcknowledged) return 'Customer signature required';
    return widget.isDelivery ? 'Submit delivery inspection' : 'Complete inspection';
  }
}

class _PhotosCard extends StatelessWidget {
  final List<InspectionPhotoSlot> photos;
  final void Function(int) onCapture;
  final void Function(int) onGallery;

  const _PhotosCard({
    required this.photos,
    required this.onCapture,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text('VEHICLE PHOTOS', style: _sectionTitleStyle()),
                const Spacer(),
                Text('Required: 6', style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, i) {
                final photo = photos[i];
                return _PhotoTile(
                  photo: photo,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCapture(i);
                  },
                  onLongPress: () => onGallery(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final InspectionPhotoSlot photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoTile({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo.hasPhoto;

    return GestureDetector(
      onTap: photo.isUploading ? null : onTap,
      onLongPress: photo.isUploading ? null : onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: photo.uploadError != null
                ? AppColors.statusRed
                : hasPhoto
                    ? AppColors.primaryOrange
                    : AppColors.divider,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto && photo.localPath != null)
              Image.file(File(photo.localPath!), fit: BoxFit.cover)
            else if (hasPhoto && photo.remoteUrl != null)
              CachedNetworkImage(
                imageUrl: Env.resolveMediaUrl(photo.remoteUrl!),
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange),
                ),
                errorWidget: (_, __, ___) => const Icon(PhosphorIconsRegular.warning),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsRegular.camera, size: 22, color: AppColors.textMuted),
                  const SizedBox(height: 4),
                  Text(photo.label, style: AppTextStyles.labelSmall.copyWith(fontSize: 9), textAlign: TextAlign.center),
                ],
              ),
            if (photo.isUploading)
              Container(
                color: Colors.black45,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            if (hasPhoto && !photo.isUploading)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.statusGreen, shape: BoxShape.circle),
                  child: const Icon(PhosphorIconsRegular.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Reuse checklist, damage, notes, signature widgets from original file — minimal stubs below.

class _ChecklistCard extends StatelessWidget {
  final List<InspectionCheckItem> items;
  final Map<String, InspectionCondition> conditions;
  final void Function(String, InspectionCondition) onSetCondition;

  const _ChecklistCard({
    required this.items,
    required this.conditions,
    required this.onSetCondition,
  });

  @override
  Widget build(BuildContext context) {
    String? currentGroup;
    final children = <Widget>[];

    for (final item in items) {
      if (item.group != currentGroup) {
        currentGroup = item.group;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(currentGroup, style: _sectionTitleStyle()),
        ));
      }
      final c = conditions[item.id] ?? InspectionCondition.none;
      children.add(_ChecklistRow(item: item, condition: c, onSet: onSetCondition));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final InspectionCheckItem item;
  final InspectionCondition condition;
  final void Function(String, InspectionCondition) onSet;

  const _ChecklistRow({required this.item, required this.condition, required this.onSet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(item.name, style: AppTextStyles.bodyMedium)),
          _CondChip(
            label: 'OK',
            active: condition == InspectionCondition.ok,
            color: AppColors.statusGreen,
            onTap: () => onSet(item.id, InspectionCondition.ok),
          ),
          _CondChip(
            label: 'Issue',
            active: condition == InspectionCondition.issue,
            color: AppColors.statusOrange,
            onTap: () => onSet(item.id, InspectionCondition.issue),
          ),
          _CondChip(
            label: 'Dmg',
            active: condition == InspectionCondition.damage,
            color: AppColors.statusRed,
            onTap: () => onSet(item.id, InspectionCondition.damage),
          ),
        ],
      ),
    );
  }
}

class _CondChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _CondChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.2) : AppColors.bgElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? color : AppColors.divider),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: active ? color : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const _NotesCard({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INSPECTOR NOTES', style: _sectionTitleStyle()),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 3,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Additional observations…',
              filled: true,
              fillColor: AppColors.bgElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _sectionTitleStyle() => GoogleFonts.sora(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: AppColors.textMuted,
    );
