import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/customers_repository.dart';
import '../../data/models/customer_models.dart';

class CreateVehicleState {
  final bool isSubmitting;
  final String? errorMessage;
  final Vehicle? createdVehicle;

  const CreateVehicleState({
    this.isSubmitting = false,
    this.errorMessage,
    this.createdVehicle,
  });

  bool get isSuccess => createdVehicle != null;

  CreateVehicleState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    Vehicle? createdVehicle,
    bool clearError = false,
  }) {
    return CreateVehicleState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdVehicle: createdVehicle ?? this.createdVehicle,
    );
  }
}

class CreateVehicleNotifier extends StateNotifier<CreateVehicleState> {
  final CustomersRepository _repo;

  CreateVehicleNotifier(this._repo) : super(const CreateVehicleState());

  Future<Vehicle?> submit({
    required String customerUuid,
    required String registrationNumber,
    required String maker,
    required String model,
    String? variant,
    int? year,
    String? color,
    String fuelType = 'petrol',
    int? odometerReading,
    bool? gpsTrackingConsent,
    String? vehicleMakeUuid,
    String? vehicleModelUuid,
    String? vehicleVariantUuid,
    String? vehicleColorUuid,
  }) async {
    if (registrationNumber.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Registration number is required.');
      return null;
    }
    if (maker.trim().isEmpty || model.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Make and model are required.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final vehicle = await _repo.createVehicle(
        customerUuid: customerUuid,
        registrationNumber: registrationNumber.trim(),
        maker: maker.trim(),
        model: model.trim(),
        variant: variant,
        year: year,
        color: color,
        fuelType: fuelType,
        odometerReading: odometerReading,
        gpsTrackingConsent: gpsTrackingConsent,
        vehicleMakeUuid: vehicleMakeUuid,
        vehicleModelUuid: vehicleModelUuid,
        vehicleVariantUuid: vehicleVariantUuid,
        vehicleColorUuid: vehicleColorUuid,
      );
      state = state.copyWith(isSubmitting: false, createdVehicle: vehicle);
      return vehicle;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not save vehicle. Check details and try again.',
      );
      return null;
    }
  }
}

final createVehicleProvider =
    StateNotifierProvider.autoDispose<CreateVehicleNotifier, CreateVehicleState>((ref) {
  return CreateVehicleNotifier(ref.watch(customersRepositoryProvider));
});
