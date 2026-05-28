import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/audit_repository.dart';
import '../../data/models/audit_models.dart';

final jobAuditProvider = FutureProvider.autoDispose
    .family<List<AuditLogEntry>, String>((ref, jobUuid) async {
  try {
    return ref.watch(auditRepositoryProvider).fetchJobAudit(jobUuid);
  } catch (e) {
    throw failureMessage(e);
  }
});

final globalAuditProvider = FutureProvider.autoDispose<List<AuditLogEntry>>((ref) async {
  try {
    return ref.watch(auditRepositoryProvider).fetchGlobalAudit();
  } catch (e) {
    throw failureMessage(e);
  }
});
