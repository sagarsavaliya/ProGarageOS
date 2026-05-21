import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/models/staff_models.dart';
import '../../data/staff_repository.dart';

class StaffListState {
  final List<StaffMember> members;
  final bool isLoading;
  final String? error;

  const StaffListState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  StaffListState copyWith({
    List<StaffMember>? members,
    bool? isLoading,
    String? error,
  }) {
    return StaffListState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StaffListNotifier extends StateNotifier<StaffListState> {
  final StaffRepository _repo;

  StaffListNotifier(this._repo) : super(const StaffListState(isLoading: true)) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final members = await _repo.listStaff();
      state = StaffListState(members: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: failureMessage(e));
    }
  }
}

final staffListProvider = StateNotifierProvider.autoDispose<StaffListNotifier, StaffListState>((ref) {
  return StaffListNotifier(ref.watch(staffRepositoryProvider));
});

final staffDetailProvider = FutureProvider.autoDispose.family<StaffMember, String>((ref, uuid) async {
  return ref.watch(staffRepositoryProvider).showStaff(uuid);
});
