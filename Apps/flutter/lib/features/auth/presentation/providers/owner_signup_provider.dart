import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';

class OwnerSignupState {
  final bool isLoading;
  final bool isLoadingPlans;
  final String? errorMessage;
  final List<SubscriptionPlanModel> plans;
  final String? selectedPlanSlug;
  final OwnerSignupResult? result;

  const OwnerSignupState({
    this.isLoading = false,
    this.isLoadingPlans = false,
    this.errorMessage,
    this.plans = const [],
    this.selectedPlanSlug,
    this.result,
  });

  OwnerSignupState copyWith({
    bool? isLoading,
    bool? isLoadingPlans,
    String? errorMessage,
    bool clearError = false,
    List<SubscriptionPlanModel>? plans,
    String? selectedPlanSlug,
    OwnerSignupResult? result,
    bool clearResult = false,
  }) {
    return OwnerSignupState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      plans: plans ?? this.plans,
      selectedPlanSlug: selectedPlanSlug ?? this.selectedPlanSlug,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

class OwnerSignupNotifier extends StateNotifier<OwnerSignupState> {
  final AuthRepository _repo;

  OwnerSignupNotifier(this._repo) : super(const OwnerSignupState()) {
    loadPlans();
  }

  Future<void> loadPlans() async {
    state = state.copyWith(isLoadingPlans: true, clearError: true);
    try {
      final plans = await _repo.fetchSubscriptionPlans();
      state = state.copyWith(
        isLoadingPlans: false,
        plans: plans,
        selectedPlanSlug: plans.isNotEmpty ? plans.first.slug : null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingPlans: false, errorMessage: failureMessage(e));
    }
  }

  void selectPlan(String slug) {
    state = state.copyWith(selectedPlanSlug: slug);
  }

  Future<bool> submit({
    required String phoneDigits,
    required String firstName,
    required String businessName,
    String? lastName,
    String? email,
  }) async {
    if (phoneDigits.length != 10) {
      state = state.copyWith(errorMessage: 'Enter a valid 10-digit mobile number.');
      return false;
    }
    if (firstName.trim().isEmpty || businessName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Your name and garage name are required.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearResult: true);
    try {
      final result = await _repo.ownerSignup(
        OwnerSignupRequest(
          phone: phoneDigits,
          firstName: firstName.trim(),
          lastName: lastName?.trim(),
          businessName: businessName.trim(),
          email: email?.trim(),
          planSlug: state.selectedPlanSlug,
        ),
      );
      state = state.copyWith(isLoading: false, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: failureMessage(e));
      return false;
    }
  }
}

final ownerSignupProvider =
    StateNotifierProvider.autoDispose<OwnerSignupNotifier, OwnerSignupState>(
  (ref) => OwnerSignupNotifier(ref.watch(authRepositoryProvider)),
);
