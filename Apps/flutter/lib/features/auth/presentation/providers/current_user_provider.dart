import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';

class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return _fetchMe();
  }

  Future<UserModel?> _fetchMe() async {
    try {
      return await ref.read(authRepositoryProvider).fetchMe();
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchMe);
  }
}

final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
  CurrentUserNotifier.new,
);

/// Technicians should not see billing/invoices in bottom nav.
final hideInvoicesTabProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  return user.role == 'technician';
});

final isOwnerProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role == 'owner';
});

final isTechnicianProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role == 'technician';
});

final showTeamTabProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return false;
  return user.role == 'owner' || user.role == 'service_advisor';
});

final showPaymentsTabProvider = Provider<bool>((ref) {
  return !ref.watch(isTechnicianProvider);
});
