import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/api/api_helpers.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/auth_repository.dart';
import '../../data/models/auth_models.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum StaffLoginStatus { idle, loading, success, error, locked }

class StaffLoginState {
  final StaffLoginStatus status;
  final String pin;
  final String currentLogin;
  final String? errorMessage;
  final int failCount;
  final int lockSecondsRemaining;
  final UserModel? savedUser;
  final bool showSwitchUser;
  final bool needsPinSetup;
  final String savedPhoneDigits;

  const StaffLoginState({
    this.status = StaffLoginStatus.idle,
    this.pin = '',
    this.currentLogin = '',
    this.errorMessage,
    this.failCount = 0,
    this.lockSecondsRemaining = 0,
    this.savedUser,
    this.showSwitchUser = false,
    this.needsPinSetup = false,
    this.savedPhoneDigits = '',
  });

  bool get isLocked => status == StaffLoginStatus.locked;
  bool get isLoading => status == StaffLoginStatus.loading;

  StaffLoginState copyWith({
    StaffLoginStatus? status,
    String? pin,
    String? currentLogin,
    String? errorMessage,
    bool clearError = false,
    int? failCount,
    int? lockSecondsRemaining,
    UserModel? savedUser,
    bool? showSwitchUser,
    bool? needsPinSetup,
    String? savedPhoneDigits,
  }) =>
      StaffLoginState(
        status: status ?? this.status,
        pin: pin ?? this.pin,
        currentLogin: currentLogin ?? this.currentLogin,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        failCount: failCount ?? this.failCount,
        lockSecondsRemaining: lockSecondsRemaining ?? this.lockSecondsRemaining,
        savedUser: savedUser ?? this.savedUser,
        showSwitchUser: showSwitchUser ?? this.showSwitchUser,
        needsPinSetup: needsPinSetup ?? this.needsPinSetup,
        savedPhoneDigits: savedPhoneDigits ?? this.savedPhoneDigits,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

const int _maxAttempts = 5;
const int _lockDurationSeconds = 30;

class StaffLoginNotifier extends StateNotifier<StaffLoginState> {
  final AuthRepository _repo;
  final SecureStorageService _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Timer? _lockTimer;

  StaffLoginNotifier(this._repo, this._storage) : super(const StaffLoginState()) {
    _init();
  }

  Future<void> _init() async {
    // Restore saved user
    final json = await _storage.getUserJson();
    final user = UserModel.fromJsonString(json);

    // Check lockout
    final expiry = await _storage.getLockExpiry();
    final failCount = await _storage.getFailCount();

    if (expiry != null && DateTime.now().isBefore(expiry)) {
      final remaining = expiry.difference(DateTime.now()).inSeconds;
      state = state.copyWith(
        savedUser: user,
        failCount: failCount,
        status: StaffLoginStatus.locked,
        lockSecondsRemaining: remaining,
      );
      _startLockTimer(expiry);
    } else {
      final savedLogin = await _storage.getSavedLogin();
      var phoneDigits = '';
      var currentLogin = '';
      if (savedLogin != null && savedLogin.isNotEmpty) {
        if (savedLogin.startsWith('+91') && savedLogin.length >= 13) {
          phoneDigits = savedLogin.substring(3);
          currentLogin = savedLogin;
        } else if (RegExp(r'^\d{10}$').hasMatch(savedLogin)) {
          phoneDigits = savedLogin;
          currentLogin = '+91$savedLogin';
        } else {
          currentLogin = savedLogin;
        }
      } else if (user?.phone != null && user!.phone!.isNotEmpty) {
        final p = user.phone!.replaceAll(RegExp(r'\D'), '');
        if (p.length >= 10) {
          phoneDigits = p.substring(p.length - 10);
          currentLogin = '+91$phoneDigits';
        }
      }
      state = state.copyWith(
        savedUser: user,
        failCount: failCount,
        currentLogin: currentLogin,
        savedPhoneDigits: phoneDigits,
        showSwitchUser: phoneDigits.isNotEmpty || (savedLogin?.contains('@') ?? false),
      );
    }
  }

  // --- PIN entry ---

  void addDigit(String digit) {
    if (state.isLocked || state.isLoading || state.pin.length >= 6) return;
    final newPin = state.pin + digit;
    state = state.copyWith(pin: newPin, clearError: true);
    if (newPin.length == 6) {
      Future.delayed(const Duration(milliseconds: 280), submitPin);
    }
  }

  void deleteDigit() {
    if (state.isLocked || state.isLoading || state.pin.isEmpty) return;
    state = state.copyWith(pin: state.pin.substring(0, state.pin.length - 1), clearError: true);
  }

  void clearPin() {
    if (state.isLocked) return;
    state = state.copyWith(pin: '', clearError: true);
  }

  // --- Submit ---

  void setCurrentLogin(String login) {
    state = state.copyWith(currentLogin: login, clearError: true, pin: '');
  }

  Future<void> submitPin() async {
    if (state.pin.length < 6 || state.isLoading || state.isLocked) return;

    final login = state.currentLogin.isNotEmpty
        ? state.currentLogin
        : (state.savedUser?.email ?? await _storage.getSavedLogin() ?? '');
    if (login.isEmpty) {
      state = state.copyWith(
        status: StaffLoginStatus.error,
        errorMessage: 'Please enter your phone or email first.',
        pin: '',
      );
      return;
    }

    state = state.copyWith(status: StaffLoginStatus.loading);

    try {
      final response = await _repo.loginStaff(
        StaffLoginRequest(login: login, pin: state.pin),
      );
      await _storage.saveToken(response.token);
      await _storage.saveUserJson(response.user.toJsonString());
      await _storage.saveSavedLogin(login);
      await _storage.clearLockout();
      state = state.copyWith(status: StaffLoginStatus.success, savedUser: response.user);
    } on DioException catch (e) {
      final code = apiErrorCode(e);
      if (code == 'PIN_SETUP_REQUIRED') {
        state = state.copyWith(
          status: StaffLoginStatus.idle,
          needsPinSetup: true,
          pin: '',
        );
        return;
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 422) {
        await _handleFailedAttempt();
      } else {
        state = state.copyWith(
          status: StaffLoginStatus.error,
          errorMessage: failureMessage(e),
          pin: '',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: StaffLoginStatus.error,
        errorMessage: failureMessage(e),
        pin: '',
      );
    }
  }

  Future<void> _handleFailedAttempt() async {
    final newFailCount = state.failCount + 1;
    await _storage.setFailCount(newFailCount);

    if (newFailCount >= _maxAttempts) {
      final expiry = DateTime.now().add(const Duration(seconds: _lockDurationSeconds));
      await _storage.setLockExpiry(expiry);
      state = state.copyWith(
        status: StaffLoginStatus.locked,
        failCount: newFailCount,
        lockSecondsRemaining: _lockDurationSeconds,
        pin: '',
      );
      _startLockTimer(expiry);
    } else {
      final remaining = _maxAttempts - newFailCount;
      state = state.copyWith(
        status: StaffLoginStatus.error,
        failCount: newFailCount,
        errorMessage: 'Incorrect PIN · $remaining attempt${remaining == 1 ? '' : 's'} remaining',
        pin: '',
      );
    }
  }

  void _startLockTimer(DateTime expiry) {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiry.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _lockTimer?.cancel();
        _storage.clearLockout();
        state = state.copyWith(
          status: StaffLoginStatus.idle,
          failCount: 0,
          lockSecondsRemaining: 0,
          pin: '',
          clearError: true,
        );
      } else {
        state = state.copyWith(lockSecondsRemaining: remaining);
      }
    });
  }

  // --- Biometric ---

  Future<void> triggerBiometric() async {
    if (kIsWeb || state.isLocked || state.isLoading) return;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        state = state.copyWith(
          status: StaffLoginStatus.error,
          errorMessage: 'Biometric not available on this device.',
        );
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to Pro Garage OS',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (authenticated) {
        final login = state.savedUser?.email ?? await _storage.getSavedLogin() ?? '';
        if (login.isEmpty) return;
        final token = await _storage.getToken();
        if (token != null) {
          state = state.copyWith(status: StaffLoginStatus.success);
        }
      }
    } catch (_) {
      // Biometric cancelled or error — silently ignore
    }
  }

  // --- Switch user ---

  void clearPinSetupRedirect() =>
      state = state.copyWith(needsPinSetup: false, clearError: true);

  void showSwitchUser() => state = state.copyWith(showSwitchUser: true, pin: '', clearError: true);
  void hideSwitchUser() => state = state.copyWith(showSwitchUser: false, pin: '', clearError: true);

  Future<void> setSavedLogin(String login) async {
    await _storage.saveSavedLogin(login);
    state = state.copyWith(showSwitchUser: false, pin: '', clearError: true);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final staffLoginProvider =
    StateNotifierProvider.autoDispose<StaffLoginNotifier, StaffLoginState>((ref) {
  return StaffLoginNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(secureStorageProvider),
  );
});
