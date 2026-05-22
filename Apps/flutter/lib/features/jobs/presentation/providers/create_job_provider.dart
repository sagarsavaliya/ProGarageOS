import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../customers/data/customers_repository.dart';
import '../../../customers/data/models/customer_models.dart';
import '../../data/garage_resources_repository.dart';
import '../../data/jobs_repository.dart';

/// Static service categories for the create-job wizard (Step 2).
class ServiceCategoryOption {
  final String uuid;
  final String code;
  final String name;
  final String durationLabel;
  final String iconLabel;
  final bool requiresInspection;
  final bool requiresApproval;

  const ServiceCategoryOption({
    required this.uuid,
    required this.code,
    required this.name,
    required this.durationLabel,
    required this.iconLabel,
    this.requiresInspection = false,
    this.requiresApproval = false,
  });

  bool get isInsuranceCategory {
    final c = code.toUpperCase();
    return c == 'ACCIDENT_RPR' || c == 'BODY_WORK';
  }
}

class BayOption {
  final String uuid;
  final String name;
  final String type;
  final String status; // available, occupied, maintenance

  const BayOption({
    required this.uuid,
    required this.name,
    required this.type,
    required this.status,
  });

  bool get isSelectable => status == 'available';
}

class TechnicianOption {
  final String uuid;
  final String name;
  final String specialty;
  final bool isAvailable;

  const TechnicianOption({
    required this.uuid,
    required this.name,
    required this.specialty,
    required this.isAvailable,
  });
}

class CreateJobState {
  final int step;
  final bool isSubmitting;
  final String? errorMessage;
  final String customerSearch;
  final List<Customer> searchResults;
  final bool isSearching;
  final Customer? selectedCustomer;
  final List<CustomerVehicleSummary> vehicles;
  final bool isLoadingVehicles;
  final CustomerVehicleSummary? selectedVehicle;
  final String complaint;
  final String odometer;
  final String? fuelLevel;
  final Set<String> selectedCategoryIds;
  final String priority;
  final String? selectedBayUuid;
  final String? selectedTechnicianUuid;
  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final CreatedJob? createdJob;
  final List<BayOption> bays;
  final List<TechnicianOption> technicians;
  final List<ServiceCategoryOption> serviceCategories;
  final bool isLoadingResources;
  final bool isLoadingCategories;
  final String insuranceCompany;
  final String claimNumber;

  const CreateJobState({
    this.step = 0,
    this.isSubmitting = false,
    this.errorMessage,
    this.customerSearch = '',
    this.searchResults = const [],
    this.isSearching = false,
    this.selectedCustomer,
    this.vehicles = const [],
    this.isLoadingVehicles = false,
    this.selectedVehicle,
    this.complaint = '',
    this.odometer = '',
    this.fuelLevel,
    this.selectedCategoryIds = const {},
    this.priority = 'normal',
    this.selectedBayUuid,
    this.selectedTechnicianUuid,
    this.scheduledDate,
    this.scheduledTime,
    this.createdJob,
    this.bays = const [],
    this.technicians = const [],
    this.serviceCategories = const [],
    this.isLoadingResources = false,
    this.isLoadingCategories = false,
    this.insuranceCompany = '',
    this.claimNumber = '',
  });

  bool get isInsuranceJobSelected => serviceCategories.any(
        (c) => selectedCategoryIds.contains(c.uuid) && c.isInsuranceCategory,
      );

  bool get step1Valid =>
      selectedCustomer != null && selectedVehicle != null;

  bool get step2Valid => selectedCategoryIds.isNotEmpty;

  bool get step3Valid => selectedBayUuid != null && selectedTechnicianUuid != null;

  bool get isSuccess => createdJob != null;

  CreateJobState copyWith({
    int? step,
    bool? isSubmitting,
    String? errorMessage,
    String? customerSearch,
    List<Customer>? searchResults,
    bool? isSearching,
    Customer? selectedCustomer,
    bool clearCustomer = false,
    List<CustomerVehicleSummary>? vehicles,
    bool? isLoadingVehicles,
    CustomerVehicleSummary? selectedVehicle,
    bool clearVehicle = false,
    String? complaint,
    String? odometer,
    String? fuelLevel,
    bool clearFuel = false,
    Set<String>? selectedCategoryIds,
    String? priority,
    String? selectedBayUuid,
    String? selectedTechnicianUuid,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
    CreatedJob? createdJob,
    bool clearCreated = false,
    List<BayOption>? bays,
    List<TechnicianOption>? technicians,
    List<ServiceCategoryOption>? serviceCategories,
    bool? isLoadingResources,
    bool? isLoadingCategories,
    String? insuranceCompany,
    String? claimNumber,
  }) {
    return CreateJobState(
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      customerSearch: customerSearch ?? this.customerSearch,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      selectedCustomer: clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      vehicles: vehicles ?? this.vehicles,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      selectedVehicle:
          clearVehicle ? null : (selectedVehicle ?? this.selectedVehicle),
      complaint: complaint ?? this.complaint,
      odometer: odometer ?? this.odometer,
      fuelLevel: clearFuel ? null : (fuelLevel ?? this.fuelLevel),
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      priority: priority ?? this.priority,
      selectedBayUuid: selectedBayUuid ?? this.selectedBayUuid,
      selectedTechnicianUuid:
          selectedTechnicianUuid ?? this.selectedTechnicianUuid,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdJob: clearCreated ? null : (createdJob ?? this.createdJob),
      bays: bays ?? this.bays,
      technicians: technicians ?? this.technicians,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      isLoadingResources: isLoadingResources ?? this.isLoadingResources,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      claimNumber: claimNumber ?? this.claimNumber,
    );
  }
}

class CreateJobNotifier extends StateNotifier<CreateJobState> {
  final JobsRepository _jobsRepo;
  final CustomersRepository _customersRepo;
  final GarageResourcesRepository _resourcesRepo;

  CreateJobNotifier(this._jobsRepo, this._customersRepo, this._resourcesRepo)
      : super(const CreateJobState()) {
    loadServiceCategories();
  }

  Future<void> loadServiceCategories() async {
    if (state.isLoadingCategories || state.serviceCategories.isNotEmpty) return;
    state = state.copyWith(isLoadingCategories: true);
    try {
      final categories = await _resourcesRepo.fetchServiceCategories();
      state = state.copyWith(serviceCategories: categories, isLoadingCategories: false);
    } catch (e) {
      state = state.copyWith(
        serviceCategories: const [],
        isLoadingCategories: false,
        errorMessage: failureMessage(e),
      );
    }
  }

  void setStep(int step) {
    state = state.copyWith(step: step, errorMessage: null);
    if (step == 2) {
      loadResources();
    }
  }

  Future<void> loadResources() async {
    if (state.isLoadingResources) return;
    state = state.copyWith(isLoadingResources: true);
    try {
      final bays = await _resourcesRepo.fetchBays();
      final techs = await _resourcesRepo.fetchTechnicians();
      state = state.copyWith(
        bays: bays,
        technicians: techs,
        isLoadingResources: false,
      );
    } catch (e) {
      state = state.copyWith(
        bays: const [],
        technicians: const [],
        isLoadingResources: false,
        errorMessage: failureMessage(e),
      );
    }
  }

  void nextStep() {
    if (state.step == 0 && !state.step1Valid) return;
    if (state.step == 1 && !state.step2Valid) return;
    if (state.step < 2) {
      final next = state.step + 1;
      state = state.copyWith(step: next, errorMessage: null);
      if (next == 2) {
        loadResources();
      }
    }
  }

  void prevStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1, errorMessage: null);
    }
  }

  Future<void> searchCustomers(String query) async {
    state = state.copyWith(customerSearch: query, isSearching: true);
    if (query.trim().length < 2) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    try {
      final result = await _customersRepo.fetchCustomers(search: query, perPage: 8);
      state = state.copyWith(searchResults: result.customers, isSearching: false);
    } catch (e) {
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
        errorMessage: failureMessage(e),
      );
    }
  }

  Future<void> selectCustomer(Customer customer) async {
    state = state.copyWith(
      selectedCustomer: customer,
      clearVehicle: true,
      searchResults: [],
      customerSearch: '',
      isLoadingVehicles: true,
    );
    try {
      final detail = await _customersRepo.fetchCustomer(customer.uuid);
      state = state.copyWith(
        vehicles: detail.vehicles,
        isLoadingVehicles: false,
        selectedVehicle:
            detail.vehicles.length == 1 ? detail.vehicles.first : null,
      );
    } catch (e) {
      state = state.copyWith(
        vehicles: const [],
        isLoadingVehicles: false,
        errorMessage: failureMessage(e),
      );
    }
  }

  void clearCustomer() {
    state = state.copyWith(
      clearCustomer: true,
      clearVehicle: true,
      vehicles: [],
    );
  }

  void selectVehicle(CustomerVehicleSummary vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
    if (vehicle.odometerReading != null && state.odometer.isEmpty) {
      state = state.copyWith(odometer: '${vehicle.odometerReading}');
    }
  }

  void setComplaint(String v) => state = state.copyWith(complaint: v);
  void setOdometer(String v) => state = state.copyWith(odometer: v);
  void setFuelLevel(String? v) => state = state.copyWith(fuelLevel: v, clearFuel: v == null);
  void setInsuranceCompany(String v) => state = state.copyWith(insuranceCompany: v);
  void setClaimNumber(String v) => state = state.copyWith(claimNumber: v);

  void toggleCategory(String id) {
    final next = Set<String>.from(state.selectedCategoryIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedCategoryIds: next);
  }

  void setPriority(String p) => state = state.copyWith(priority: p);
  void selectBay(String uuid) => state = state.copyWith(selectedBayUuid: uuid);
  void selectTechnician(String uuid) =>
      state = state.copyWith(selectedTechnicianUuid: uuid);

  void setSchedule(DateTime date, TimeOfDay time) {
    state = state.copyWith(scheduledDate: date, scheduledTime: time);
  }

  Future<CreatedJob?> submit() async {
    if (!state.step3Valid || state.selectedCustomer == null || state.selectedVehicle == null) {
      return null;
    }
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      DateTime? scheduled;
      if (state.scheduledDate != null && state.scheduledTime != null) {
        scheduled = DateTime(
          state.scheduledDate!.year,
          state.scheduledDate!.month,
          state.scheduledDate!.day,
          state.scheduledTime!.hour,
          state.scheduledTime!.minute,
        );
      }

      final created = await _jobsRepo.createJob({
        'customer_uuid': state.selectedCustomer!.uuid,
        'vehicle_uuid': state.selectedVehicle!.uuid,
        'priority': state.priority,
        if (state.complaint.isNotEmpty) 'customer_complaint': state.complaint,
        if (state.odometer.isNotEmpty)
          'odometer_at_intake': int.tryParse(state.odometer.replaceAll(',', '')),
        if (state.fuelLevel != null) 'fuel_level': state.fuelLevel,
        if (scheduled != null) 'scheduled_start_at': scheduled.toIso8601String(),
        if (state.selectedCategoryIds.isNotEmpty)
          'service_category_uuids': state.selectedCategoryIds.toList(),
        if (state.isInsuranceJobSelected) ...{
          'is_insurance_job': true,
          if (state.insuranceCompany.trim().isNotEmpty)
            'insurance_company': state.insuranceCompany.trim(),
          if (state.claimNumber.trim().isNotEmpty) 'claim_number': state.claimNumber.trim(),
        },
        'delivery_method': 'pickup',
      });

      await _jobsRepo.updateJob(created.uuid, {
        if (state.selectedTechnicianUuid != null)
          'primary_technician_uuid': state.selectedTechnicianUuid,
        if (state.selectedBayUuid != null) 'assigned_bay_uuid': state.selectedBayUuid,
      });

      await _jobsRepo.updateStatus(created.uuid, 'inspecting');

      state = state.copyWith(isSubmitting: false, createdJob: created);
      return created;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: failureMessage(e),
      );
      return null;
    }
  }

  void reset() => state = const CreateJobState();
}

final createJobProvider =
    StateNotifierProvider.autoDispose<CreateJobNotifier, CreateJobState>((ref) {
  return CreateJobNotifier(
    ref.watch(jobsRepositoryProvider),
    ref.watch(customersRepositoryProvider),
    ref.watch(garageResourcesRepositoryProvider),
  );
});
