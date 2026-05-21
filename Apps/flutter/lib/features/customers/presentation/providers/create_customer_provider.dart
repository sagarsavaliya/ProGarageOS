import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/customers_repository.dart';
import '../../data/models/customer_models.dart';

class CreateCustomerState {
  final bool isSubmitting;
  final String? errorMessage;
  final Customer? createdCustomer;

  const CreateCustomerState({
    this.isSubmitting = false,
    this.errorMessage,
    this.createdCustomer,
  });

  bool get isSuccess => createdCustomer != null;

  CreateCustomerState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    Customer? createdCustomer,
    bool clearError = false,
    bool clearCreated = false,
  }) {
    return CreateCustomerState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdCustomer: clearCreated ? null : (createdCustomer ?? this.createdCustomer),
    );
  }
}

class CreateCustomerNotifier extends StateNotifier<CreateCustomerState> {
  final CustomersRepository _repo;

  CreateCustomerNotifier(this._repo) : super(const CreateCustomerState());

  Future<Customer?> submit({
    required String firstName,
    required String lastName,
    required String phonePrimary,
    String? email,
    String? phoneSecondary,
    bool marketingOptIn = false,
    String? internalNotes,
  }) async {
    if (firstName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'First name is required.');
      return null;
    }
    if (phonePrimary.trim().length < 10) {
      state = state.copyWith(errorMessage: 'Enter a valid 10-digit mobile number.');
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final phone = phonePrimary.startsWith('+') ? phonePrimary : '+91$phonePrimary';
      final customer = await _repo.createCustomer(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phonePrimary: phone,
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        phoneSecondary: phoneSecondary?.trim().isEmpty == true ? null : phoneSecondary?.trim(),
        marketingOptIn: marketingOptIn,
        internalNotes: internalNotes?.trim().isEmpty == true ? null : internalNotes?.trim(),
      );
      state = state.copyWith(isSubmitting: false, createdCustomer: customer);
      return customer;
    } on DioException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _mapDioError(e),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Could not save customer. Please try again.',
      );
      return null;
    }
  }

  String _mapDioError(DioException e) {
    if (e.response?.statusCode == 422) {
      return 'Please check the details and try again.';
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach server. Check network and try again.';
    }
    return 'Could not save customer. Please try again.';
  }

  void reset() => state = const CreateCustomerState();
}

final createCustomerProvider =
    StateNotifierProvider.autoDispose<CreateCustomerNotifier, CreateCustomerState>((ref) {
  return CreateCustomerNotifier(ref.watch(customersRepositoryProvider));
});
