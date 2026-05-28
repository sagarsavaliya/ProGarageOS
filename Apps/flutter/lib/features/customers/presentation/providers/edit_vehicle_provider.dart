import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/customers_repository.dart';
import '../../data/models/customer_models.dart';
import 'customers_provider.dart';

class EditVehicleState {
  final bool isSubmitting;
  final String? errorMessage;

  const EditVehicleState({this.isSubmitting = false, this.errorMessage});

  EditVehicleState copyWith({bool? isSubmitting, String? errorMessage, bool clearError = false}) {
    return EditVehicleState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EditVehicleNotifier extends StateNotifier<EditVehicleState> {
  final CustomersRepository _repo;
  final Ref _ref;
  final String _vehicleUuid;
  final String _customerUuid;

  EditVehicleNotifier(this._repo, this._ref, this._vehicleUuid, this._customerUuid)
      : super(const EditVehicleState());

  Future<Vehicle?> submit({
    required String maker,
    required String model,
    String? variant,
    int? year,
    String? color,
    required String fuelType,
    int? odometerReading,
    bool? gpsTrackingConsent,
    String? vehicleMakeUuid,
    String? vehicleModelUuid,
    String? vehicleVariantUuid,
    String? vehicleColorUuid,
  }) async {
    if (maker.trim().isEmpty || model.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Make and model are required.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final vehicle = await _repo.updateVehicle(
        uuid: _vehicleUuid,
        maker: maker.trim(),
        model: model.trim(),
        variant: variant?.trim().isEmpty == true ? null : variant?.trim(),
        year: year,
        color: color?.trim().isEmpty == true ? null : color?.trim(),
        fuelType: fuelType,
        odometerReading: odometerReading,
        gpsTrackingConsent: gpsTrackingConsent,
        vehicleMakeUuid: vehicleMakeUuid,
        vehicleModelUuid: vehicleModelUuid,
        vehicleVariantUuid: vehicleVariantUuid,
        vehicleColorUuid: vehicleColorUuid,
      );
      _ref.invalidate(customerDetailProvider(_customerUuid));
      _ref.invalidate(customerVehiclesProvider(_customerUuid));
      _ref.invalidate(vehicleByUuidProvider(_vehicleUuid));
      state = state.copyWith(isSubmitting: false);
      return vehicle;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: failureMessage(e));
      return null;
    }
  }
}

final editVehicleProvider = StateNotifierProvider.autoDispose
    .family<EditVehicleNotifier, EditVehicleState, ({String vehicleUuid, String customerUuid})>(
  (ref, params) {
    return EditVehicleNotifier(
      ref.watch(customersRepositoryProvider),
      ref,
      params.vehicleUuid,
      params.customerUuid,
    );
  },
);
