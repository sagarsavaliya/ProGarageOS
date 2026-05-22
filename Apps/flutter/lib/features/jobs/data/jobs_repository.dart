import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/inspection_models.dart';
import '../../../core/api/api_client.dart';
import 'models/estimate_models.dart';
import 'models/job_models.dart';

class JobsRepository {
  final Dio _dio;

  const JobsRepository(this._dio);

  /// GET /jobs — paginated, filterable list.
  Future<PaginatedJobs> fetchJobs({
    String? status,
    String? search,
    int page = 1,
    int perPage = 25,
  }) async {
    final response = await _dio.get(
      '/jobs',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': perPage,
      },
    );
    return PaginatedJobs.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /jobs/{uuid} — full job detail.
  Future<JobDetail> fetchJob(String uuid) async {
    final response = await _dio.get('/jobs/$uuid');
    return JobDetail.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /jobs — create a new service job.
  Future<CreatedJob> createJob(Map<String, dynamic> body) async {
    final response = await _dio.post('/jobs', data: body);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return CreatedJob(
      uuid: data['uuid'] as String? ?? '',
      jobNumber: data['job_number'] as String? ?? 'JOB-NEW',
    );
  }

  /// PATCH /jobs/{uuid} — assign bay, technician, schedule.
  Future<void> updateJob(String uuid, Map<String, dynamic> body) async {
    await _dio.patch('/jobs/$uuid', data: body);
  }

  /// PATCH /jobs/{uuid}/insurance-claim
  Future<void> updateInsuranceClaim(
    String uuid, {
    String? insuranceClaimStatus,
    String? insuranceCompany,
    String? claimNumber,
    double? customerLiabilityAmount,
    double? jobInsuranceClaimAmount,
  }) async {
    await _dio.patch(
      '/jobs/$uuid/insurance-claim',
      data: {
        if (insuranceClaimStatus != null) 'insurance_claim_status': insuranceClaimStatus,
        if (insuranceCompany != null) 'insurance_company': insuranceCompany,
        if (claimNumber != null) 'claim_number': claimNumber,
        if (customerLiabilityAmount != null)
          'customer_liability_amount': customerLiabilityAmount,
        if (jobInsuranceClaimAmount != null)
          'job_insurance_claim_amount': jobInsuranceClaimAmount,
      },
    );
  }

  /// PATCH /jobs/{uuid}/status — transition job status.
  Future<void> updateStatus(String uuid, String status, {String? notes}) async {
    await _dio.patch(
      '/jobs/$uuid/status',
      data: {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  /// GET /jobs/{uuid}/inspections — load saved intake checklist.
  Future<IntakeInspectionData> fetchInspection(
    String uuid, {
    String phase = 'intake',
  }) async {
    final response = await _dio.get(
      '/jobs/$uuid/inspections',
      queryParameters: {'phase': phase},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return _parseInspectionData(data);
  }

  IntakeInspectionData _parseInspectionData(Map<String, dynamic> data) {
    final conditions = <String, InspectionCondition>{};
    for (final item in data['items'] as List<dynamic>? ?? []) {
      final m = item as Map<String, dynamic>;
      final key = m['component_key'] as String? ?? '';
      conditions[key] = _conditionFromApi(m['condition_status'] as String? ?? 'na');
    }

    final damageZones = <String, DamageSeverity>{};
    for (final zone in data['damage_zones'] as List<dynamic>? ?? []) {
      final m = zone as Map<String, dynamic>;
      final name = m['zone'] as String? ?? '';
      damageZones[name] = _damageFromApi(m['severity'] as String? ?? 'none');
    }

    final photos = (data['photos'] as List<dynamic>? ?? [])
        .map((e) => InspectionPhotoSlot.fromApi(e as Map<String, dynamic>))
        .toList();

    return IntakeInspectionData(
      notes: data['notes'] as String?,
      customerAcknowledged: data['customer_acknowledged'] as bool? ?? false,
      conditions: conditions,
      damageZones: damageZones,
      photos: photos,
      isLoaded: true,
    );
  }

  InspectionCondition _conditionFromApi(String s) {
    return switch (s) {
      'good' => InspectionCondition.ok,
      'fair' => InspectionCondition.issue,
      'poor' => InspectionCondition.issue,
      'damaged' => InspectionCondition.damage,
      'missing' => InspectionCondition.damage,
      _ => InspectionCondition.none,
    };
  }

  DamageSeverity _damageFromApi(String s) {
    return switch (s) {
      'minor' => DamageSeverity.minor,
      'moderate' => DamageSeverity.minor,
      'severe' => DamageSeverity.major,
      _ => DamageSeverity.none,
    };
  }

  /// POST /jobs/{uuid}/inspections/photos — upload one image.
  Future<InspectionPhotoSlot> uploadInspectionPhoto({
    required String jobUuid,
    required String slot,
    required String label,
    required File file,
  }) async {
    final formData = FormData.fromMap({
      'slot': slot,
      'label': label,
      'photo': await MultipartFile.fromFile(
        file.path,
        filename: '$slot.jpg',
      ),
    });
    final response = await _dio.post(
      '/jobs/$jobUuid/inspections/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return InspectionPhotoSlot.fromApi(data).copyWith(localPath: file.path);
  }

  /// POST /jobs/{uuid}/inspections — save intake or delivery checklist.
  Future<void> saveInspection(String uuid, Map<String, dynamic> body) async {
    await _dio.post('/jobs/$uuid/inspections', data: body);
  }

  /// GET /jobs/{uuid}/inspections/compare — new damage since intake.
  Future<InspectionCompareResult> compareInspections(String uuid) async {
    final response = await _dio.get('/jobs/$uuid/inspections/compare');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return InspectionCompareResult.fromJson(data);
  }

  /// GET /jobs/{uuid}/inspections/pdf?phase=
  Future<String?> getInspectionPdfUrl(String uuid, {String phase = 'intake'}) async {
    final response = await _dio.get(
      '/jobs/$uuid/inspections/pdf',
      queryParameters: {'phase': phase},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return data['url'] as String?;
  }

  /// GET /inspection-templates?phase=
  Future<List<InspectionCheckItem>> fetchInspectionTemplate(String phase) async {
    final response = await _dio.get(
      '/inspection-templates',
      queryParameters: {'phase': phase},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) {
      final m = e as Map<String, dynamic>;
      return InspectionCheckItem(
        id: m['component_key'] as String? ?? '',
        group: m['category'] as String? ?? 'General',
        name: m['component_name'] as String? ?? '',
      );
    }).toList();
  }

  /// GET /jobs/{uuid}/estimate
  Future<JobEstimate> fetchEstimate(String uuid) async {
    final response = await _dio.get('/jobs/$uuid/estimate');
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return JobEstimate.fromJson(data);
  }

  /// PUT /jobs/{uuid}/estimate
  Future<JobEstimate> updateEstimate(String uuid, Map<String, dynamic> body) async {
    final response = await _dio.put('/jobs/$uuid/estimate', data: body);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return JobEstimate.fromJson(data);
  }

  /// POST /jobs/{uuid}/estimate/send
  Future<void> sendEstimate(String uuid) async {
    await _dio.post('/jobs/$uuid/estimate/send');
  }

  /// POST /jobs/{uuid}/estimate/approve
  Future<JobEstimate> approveEstimate(String uuid, {String? notes}) async {
    final response = await _dio.post(
      '/jobs/$uuid/estimate/approve',
      data: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return JobEstimate.fromJson(data);
  }

  /// POST /jobs/{uuid}/estimate/reject
  Future<JobEstimate> rejectEstimate(String uuid, {required String notes}) async {
    final response = await _dio.post(
      '/jobs/$uuid/estimate/reject',
      data: {'notes': notes},
    );
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return JobEstimate.fromJson(data);
  }

  /// GET /jobs/{uuid}/tasks
  Future<List<TaskItem>> fetchTasks(String jobUuid) async {
    final response = await _dio.get('/jobs/$jobUuid/tasks');
    final list = (response.data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return list.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /jobs/{uuid}/tasks
  Future<TaskItem> createTask(String jobUuid, Map<String, dynamic> body) async {
    final response = await _dio.post('/jobs/$jobUuid/tasks', data: body);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return TaskItem.fromJson(data);
  }

  /// PATCH /jobs/{uuid}/tasks/{taskId}
  Future<TaskItem> updateTask(String jobUuid, int taskId, Map<String, dynamic> body) async {
    final response = await _dio.patch('/jobs/$jobUuid/tasks/$taskId', data: body);
    final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    return TaskItem.fromJson(data);
  }

  /// DELETE /jobs/{uuid}/tasks/{taskId}
  Future<void> deleteTask(String jobUuid, int taskId) async {
    await _dio.delete('/jobs/$jobUuid/tasks/$taskId');
  }
}

class CreatedJob {
  final String uuid;
  final String jobNumber;

  const CreatedJob({required this.uuid, required this.jobNumber});
}

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(ref.watch(apiClientProvider));
});
