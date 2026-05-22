import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../settings/data/tenant_repository.dart';
import '../../data/onboarding_draft_service.dart';

class GarageSetupWizardScreen extends ConsumerStatefulWidget {
  const GarageSetupWizardScreen({super.key});

  @override
  ConsumerState<GarageSetupWizardScreen> createState() => _GarageSetupWizardScreenState();
}

class _GarageSetupWizardScreenState extends ConsumerState<GarageSetupWizardScreen> {
  PageController? _pageController;
  int _step = 0;
  bool _loading = false;
  bool _initializing = true;
  String? _error;
  String? _tenantUuid;
  bool _offlineDraftOnly = false;

  final _businessNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bayCountController = TextEditingController(text: '2');

  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _businessNameController,
      _gstinController,
      _addressController,
      _phoneController,
      _bayCountController,
    ]) {
      c.addListener(_scheduleDraftSave);
    }
    _initialize();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _pageController?.dispose();
    for (final c in [
      _businessNameController,
      _gstinController,
      _addressController,
      _phoneController,
      _bayCountController,
    ]) {
      c.removeListener(_scheduleDraftSave);
      c.dispose();
    }
    super.dispose();
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 450), _persistDraftLocal);
  }

  SetupDraft _currentDraft() {
    return SetupDraft(
      businessName: _businessNameController.text.trim(),
      gstNumber: _gstinController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      bayCount: _bayCountController.text.trim(),
      lastStep: pageIndexToSetupStep(_step),
    );
  }

  Future<void> _persistDraftLocal() async {
    final tenantUuid = _tenantUuid;
    if (tenantUuid == null) return;
    await ref.read(onboardingDraftServiceProvider).save(tenantUuid, _currentDraft());
  }

  Future<void> _initialize() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final tenantUuid = user?.tenantUuid;
    if (tenantUuid == null || tenantUuid.isEmpty) {
      setState(() {
        _initializing = false;
        _error = 'Could not load garage account. Sign in again.';
      });
      return;
    }

    _tenantUuid = tenantUuid;
    final draftService = ref.read(onboardingDraftServiceProvider);
    final localDraft = await draftService.load(tenantUuid);

    TenantProfile? profile;
    try {
      profile = await ref.read(tenantRepositoryProvider).fetchProfile();
      if (profile.isSetupComplete) {
        await ref.read(secureStorageProvider).setGarageSetupCompleted(tenantUuid, true);
        await draftService.clear(tenantUuid);
        if (mounted) context.go('/dashboard');
        return;
      }
    } catch (_) {
      _offlineDraftOnly = localDraft != null;
    }

    _applyFields(profile, localDraft);

    var resumeStep = profile != null
        ? setupStepToPageIndex(profile.setupStep)
        : setupStepToPageIndex(localDraft?.lastStep ?? 'welcome');

    if (resumeStep < 0) resumeStep = 0;
    if (resumeStep > 3) resumeStep = 3;

    _pageController = PageController(initialPage: resumeStep);

    if (mounted) {
      setState(() {
        _step = resumeStep;
        _initializing = false;
        if (profile == null && localDraft == null) {
          _error = 'Could not reach server. Check connection and retry.';
        }
      });
    }
  }

  void _applyFields(TenantProfile? profile, SetupDraft? draft) {
    if (profile != null) {
      if (profile.businessName.isNotEmpty) {
        _businessNameController.text = profile.businessName;
      }
      if (profile.gstNumber?.isNotEmpty == true) {
        _gstinController.text = profile.gstNumber!;
      }
      final addressParts = [profile.address, profile.city, profile.state, profile.pincode]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
      if (addressParts.isNotEmpty) _addressController.text = addressParts;
      if (profile.phone?.isNotEmpty == true) _phoneController.text = profile.phone!;
      if (profile.setupBayCount != null) {
        _bayCountController.text = '${profile.setupBayCount}';
      }
    }

    if (draft != null) {
      if (draft.businessName?.isNotEmpty == true) {
        _businessNameController.text = draft.businessName!;
      }
      if (draft.gstNumber?.isNotEmpty == true) _gstinController.text = draft.gstNumber!;
      if (draft.address?.isNotEmpty == true) _addressController.text = draft.address!;
      if (draft.phone?.isNotEmpty == true) _phoneController.text = draft.phone!;
      if (draft.bayCount?.isNotEmpty == true) _bayCountController.text = draft.bayCount!;
    }

    if (_businessNameController.text.isEmpty) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user?.garageName != null) {
        _businessNameController.text = user!.garageName!;
      }
    }
  }

  Future<void> _syncSetupStep(String step, {int? bayCount}) async {
    try {
      await ref.read(tenantRepositoryProvider).updateSetup(
            setupStep: step,
            setupBayCount: bayCount,
          );
      _offlineDraftOnly = false;
    } catch (_) {
      // Step saved locally in draft; server sync retries on next save.
    }
  }

  Future<void> _completeSetup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(tenantRepositoryProvider).updateSetup(complete: true);
      final tenantUuid = _tenantUuid;
      if (tenantUuid != null) {
        await ref.read(secureStorageProvider).setGarageSetupCompleted(tenantUuid, true);
        await ref.read(onboardingDraftServiceProvider).clear(tenantUuid);
      }
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = failureMessage(e);
      });
    }
  }

  Future<void> _finishLater() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('Finish later?', style: AppTextStyles.titleMedium),
        content: Text(
          'Your progress is saved. You can complete setup anytime from Settings.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Go to dashboard'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _persistDraftLocal();
    await _syncSetupStep(pageIndexToSetupStep(_step));
    if (!mounted) return;
    context.go('/dashboard');
  }

  Future<void> _saveDetails() async {
    if (_businessNameController.text.trim().isEmpty) {
      setState(() => _error = 'Business name is required.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    await _persistDraftLocal();

    try {
      await ref.read(tenantRepositoryProvider).updateProfile(
            businessName: _businessNameController.text.trim(),
            gstNumber: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );
      await _syncSetupStep('bays');
      ref.invalidate(tenantProfileProvider);
      setState(() => _loading = false);
      _goToStep(2);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = failureMessage(e);
      });
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController?.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
    _scheduleDraftSave();
  }

  Future<void> _nextFromWelcome() async {
    await _syncSetupStep('details');
    _goToStep(1);
  }

  Future<void> _nextFromBays() async {
    final bays = int.tryParse(_bayCountController.text.trim()) ?? 2;
    final safeBays = bays.clamp(1, 50);
    _bayCountController.text = '$safeBays';
    await _persistDraftLocal();
    await _syncSetupStep('done', bayCount: safeBays);
    _goToStep(3);
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryOrange),
              const SizedBox(height: 16),
              Text('Restoring your progress…', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
    }

    if (_pageController == null && _error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgSurface,
          title: Text('Setup', style: AppTextStyles.titleMedium),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                AppButton(label: 'Retry', onPressed: () {
                  setState(() {
                    _initializing = true;
                    _error = null;
                  });
                  _initialize();
                }),
              ],
            ),
          ),
        ),
      );
    }

    final user = ref.watch(currentUserProvider).valueOrNull;
    final garageName = user?.garageName ?? 'your garage';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Setup', style: AppTextStyles.titleMedium),
        actions: [
          TextButton(
            onPressed: _finishLater,
            child: Text('Finish later', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_offlineDraftOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.statusOrangeBg,
              child: Text(
                'Offline — showing saved draft. Connect to sync to your garage account.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryOrange),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primaryOrange : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(_error!, style: TextStyle(color: AppColors.statusRed)),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _WelcomeStep(garageName: garageName, onNext: () => _nextFromWelcome()),
                _DetailsStep(
                  businessNameController: _businessNameController,
                  gstinController: _gstinController,
                  addressController: _addressController,
                  phoneController: _phoneController,
                  loading: _loading,
                  onSave: _saveDetails,
                ),
                _BaysStep(
                  bayCountController: _bayCountController,
                  onNext: () => _nextFromBays(),
                ),
                _DoneStep(
                  loading: _loading,
                  onFinish: _completeSetup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final String garageName;
  final VoidCallback onNext;

  const _WelcomeStep({required this.garageName, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(PhosphorIconsRegular.wrench, size: 40, color: AppColors.primaryOrange),
          const SizedBox(height: 20),
          Text("Let's set up $garageName", style: AppTextStyles.displayMedium.copyWith(fontSize: 26)),
          const SizedBox(height: 12),
          Text(
            'Takes about 2 minutes. You can pause anytime — we save your progress.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          AppButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  final TextEditingController businessNameController;
  final TextEditingController gstinController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final bool loading;
  final VoidCallback onSave;

  const _DetailsStep({
    required this.businessNameController,
    required this.gstinController,
    required this.addressController,
    required this.phoneController,
    required this.loading,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Garage details', style: AppTextStyles.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Used on GST invoices. Only business name is required.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        _field('Legal business name *', businessNameController),
        const SizedBox(height: 12),
        _field('GSTIN (optional)', gstinController),
        const SizedBox(height: 12),
        _field('Address (optional)', addressController, maxLines: 3),
        const SizedBox(height: 12),
        _field('Phone (optional)', phoneController, keyboard: TextInputType.phone),
        const SizedBox(height: 24),
        AppButton(label: loading ? 'Saving…' : 'Save & continue', onPressed: loading ? null : onSave),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _BaysStep extends StatelessWidget {
  final TextEditingController bayCountController;
  final VoidCallback onNext;

  const _BaysStep({required this.bayCountController, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service bays', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Optional — helps plan workshop capacity. You can skip or change later.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: bayCountController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Number of bays',
              filled: true,
              fillColor: AppColors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const Spacer(),
          AppButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  final bool loading;
  final VoidCallback onFinish;

  const _DoneStep({required this.loading, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Icon(PhosphorIconsRegular.checkCircle, size: 48, color: AppColors.statusGreen),
          const SizedBox(height: 20),
          Text("You're ready", style: AppTextStyles.displayMedium.copyWith(fontSize: 26)),
          const SizedBox(height: 12),
          Text(
            'Create your first job or explore the dashboard.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          AppButton(
            label: loading ? 'Finishing…' : 'Go to dashboard',
            onPressed: loading ? null : onFinish,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: loading ? null : () => context.push('/jobs/add'),
            child: const Text('Create first job'),
          ),
        ],
      ),
    );
  }
}
