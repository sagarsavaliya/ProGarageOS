import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/models/staff_models.dart';
import '../../data/staff_repository.dart';

class CreateStaffState {
  final bool isSubmitting;
  final String? errorMessage;
  final StaffMember? created;

  const CreateStaffState({
    this.isSubmitting = false,
    this.errorMessage,
    this.created,
  });

  CreateStaffState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    StaffMember? created,
  }) {
    return CreateStaffState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      created: created ?? this.created,
    );
  }
}

class CreateStaffNotifier extends StateNotifier<CreateStaffState> {
  final StaffRepository _repo;

  CreateStaffNotifier(this._repo) : super(const CreateStaffState());

  Future<StaffMember?> submit({
    required String firstName,
    String? lastName,
    required String phone,
    String? email,
    required String role,
    required String pin,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final member = await _repo.createStaff(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        role: role,
        pin: pin,
      );
      state = CreateStaffState(created: member);
      return member;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: failureMessage(e));
      return null;
    }
  }
}

final createStaffProvider =
    StateNotifierProvider.autoDispose<CreateStaffNotifier, CreateStaffState>((ref) {
  return CreateStaffNotifier(ref.watch(staffRepositoryProvider));
});
