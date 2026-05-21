import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

const _tokenKey = 'auth_token';
const _userJsonKey = 'auth_user_json';
const _savedLoginKey = 'saved_login';
const _failCountKey = 'pin_fail_count';
const _lockExpiryKey = 'pin_lock_expiry';

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

  // --- Clear all ---
  Future<void> clearAll() => _storage.deleteAll();
}
