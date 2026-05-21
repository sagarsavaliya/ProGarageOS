import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_helpers.dart';
import '../../data/customers_repository.dart';
import '../../data/models/customer_models.dart';
import 'customers_provider.dart';

class EditCustomerState {
  final bool isSubmitting;
  final String? errorMessage;

  const EditCustomerState({this.isSubmitting = false, this.errorMessage});

  EditCustomerState copyWith({bool? isSubmitting, String? errorMessage, bool clearError = false}) {
    return EditCustomerState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EditCustomerNotifier extends StateNotifier<EditCustomerState> {
  final CustomersRepository _repo;
  final Ref _ref;
  final String _customerUuid;

  EditCustomerNotifier(this._repo, this._ref, this._customerUuid)
      : super(const EditCustomerState());

  Future<CustomerDetail?> submit({
    required String firstName,
    required String lastName,
    String? email,
    bool marketingOptIn = false,
    String? internalNotes,
  }) async {
    if (firstName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'First name is required.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final detail = await _repo.updateCustomer(
        uuid: _customerUuid,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        marketingOptIn: marketingOptIn,
        internalNotes: internalNotes?.trim().isEmpty == true ? null : internalNotes?.trim(),
      );
      _ref.invalidate(customerDetailProvider(_customerUuid));
      _ref.read(customersProvider.notifier).refresh();
      state = state.copyWith(isSubmitting: false);
      return detail;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: failureMessage(e));
      return null;
    }
  }
}

final editCustomerProvider = StateNotifierProvider.autoDispose
    .family<EditCustomerNotifier, EditCustomerState, String>((ref, customerUuid) {
  return EditCustomerNotifier(
    ref.watch(customersRepositoryProvider),
    ref,
    customerUuid,
  );
});
