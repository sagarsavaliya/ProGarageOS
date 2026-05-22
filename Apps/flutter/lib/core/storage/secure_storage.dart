import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

const _tokenKey = 'auth_token';
const _userJsonKey = 'auth_user_json';
const _savedLoginKey = 'saved_login';
const _failCountKey = 'pin_fail_count';
const _lockExpiryKey = 'pin_lock_expiry';
const _onboardingCompletedKey = 'onboarding_completed';
const _garageSetupPrefix = 'garage_setup_completed_';
const _gpsDefaultConsentKey = 'gps_default_consent_enabled';

@Riverpod(keepAlive: true)
SecureStorageService secureStorage(Ref ref) => SecureStorageService();

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // --- Token ---
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
  Future<bool> hasToken() async => (await getToken()) != null;

  // --- User JSON ---
  Future<void> saveUserJson(String json) => _storage.write(key: _userJsonKey, value: json);
  Future<String?> getUserJson() => _storage.read(key: _userJsonKey);
  Future<void> clearUserJson() => _storage.delete(key: _userJsonKey);

  // --- Saved login (last used login identifier) ---
  Future<void> saveSavedLogin(String login) => _storage.write(key: _savedLoginKey, value: login);
  Future<String?> getSavedLogin() => _storage.read(key: _savedLoginKey);

  // --- PIN fail count + lockout ---
  Future<int> getFailCount() async {
    final v = await _storage.read(key: _failCountKey);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> setFailCount(int count) =>
      _storage.write(key: _failCountKey, value: count.toString());

  Future<DateTime?> getLockExpiry() async {
    final v = await _storage.read(key: _lockExpiryKey);
    if (v == null) return null;
    final ms = int.tryParse(v);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLockExpiry(DateTime expiry) =>
      _storage.write(key: _lockExpiryKey, value: expiry.millisecondsSinceEpoch.toString());

  Future<void> clearLockout() async {
    await _storage.delete(key: _failCountKey);
    await _storage.delete(key: _lockExpiryKey);
  }

  // --- Onboarding flags ---
  Future<bool> isOnboardingCompleted() async =>
      (await _storage.read(key: _onboardingCompletedKey)) == 'true';

  Future<void> setOnboardingCompleted(bool value) =>
      _storage.write(key: _onboardingCompletedKey, value: value.toString());

  Future<bool> isGarageSetupCompleted(String tenantUuid) async =>
      (await _storage.read(key: '$_garageSetupPrefix$tenantUuid')) == 'true';

  Future<void> setGarageSetupCompleted(String tenantUuid, bool value) =>
      _storage.write(key: '$_garageSetupPrefix$tenantUuid', value: value.toString());

  // --- GPS default for new vehicles (local preference) ---
  Future<bool> isGpsDefaultConsentEnabled() async =>
      (await _storage.read(key: _gpsDefaultConsentKey)) == 'true';

  Future<void> setGpsDefaultConsentEnabled(bool value) =>
      _storage.write(key: _gpsDefaultConsentKey, value: value.toString());

  // --- Generic read/write for draft JSON (used by onboarding) ---
  Future<String?> readRaw(String key) => _storage.read(key: key);
  Future<void> writeRaw(String key, String value) => _storage.write(key: key, value: value);
  Future<void> deleteRaw(String key) => _storage.delete(key: key);

  // --- Clear session (logout) — keeps device prefs like onboarding + saved login ---
  Future<void> clearSession() async {
    await clearToken();
    await clearUserJson();
    await clearLockout();
  }

  // --- Clear all (factory reset only) ---
  Future<void> clearAll() => _storage.deleteAll();
}
