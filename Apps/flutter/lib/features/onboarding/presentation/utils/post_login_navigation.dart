import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../settings/data/tenant_repository.dart';
import '../../../../core/storage/secure_storage.dart';

/// Resolves where to send the user immediately after login.
Future<String> resolvePostLoginRoute(WidgetRef ref) async {
  final storage = ref.read(secureStorageProvider);
  final tenantRepo = ref.read(tenantRepositoryProvider);

  UserModel user;
  try {
    user = await ref.read(authRepositoryProvider).fetchMe();
    await ref.read(currentUserProvider.notifier).refresh();
  } catch (_) {
    final cached = UserModel.fromJsonString(await storage.getUserJson());
    if (cached == null) return '/dashboard';
    user = cached;
  }

  if (user.role != 'owner') return '/dashboard';

  final tenantUuid = user.tenantUuid;
  if (tenantUuid == null || tenantUuid.isEmpty) return '/dashboard';

  final setupDone = await resolveGarageSetupComplete(
    tenantRepo: tenantRepo,
    storage: storage,
    tenantUuid: tenantUuid,
  );

  return setupDone ? '/dashboard' : '/onboarding/setup';
}
