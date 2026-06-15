import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((_) => SecureStorage());

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // In-memory fallback for web when IndexedDB crypto fails.
  // Values survive the session but are cleared on page refresh (acceptable).
  static final Map<String, String> _mem = {};

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserRole = 'user_role';
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyPatientCode = 'patient_code';
  static const _keyLanguage = 'app_language';

  Future<void> _write(String key, String value) async {
    _mem[key] = value;
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> _read(String key) async {
    try {
      final v = await _storage.read(key: key);
      if (v != null) _mem[key] = v;
      return v ?? _mem[key];
    } catch (_) {
      return _mem[key];
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _write(_keyAccessToken, accessToken),
      _write(_keyRefreshToken, refreshToken),
    ]);
  }

  Future<void> saveAccessToken(String token) => _write(_keyAccessToken, token);

  Future<String?> getAccessToken() => _read(_keyAccessToken);
  Future<String?> getRefreshToken() => _read(_keyRefreshToken);

  Future<void> saveUserInfo({
    required String userId,
    required String userRole,
    required String userName,
    String? patientCode,
  }) async {
    await Future.wait([
      _write(_keyUserId, userId),
      _write(_keyUserRole, userRole),
      _write(_keyUserName, userName),
      if (patientCode != null) _write(_keyPatientCode, patientCode),
    ]);
  }

  Future<String?> getUserId() => _read(_keyUserId);
  Future<String?> getUserRole() => _read(_keyUserRole);
  Future<String?> getUserName() => _read(_keyUserName);
  Future<String?> getPatientCode() => _read(_keyPatientCode);

  Future<void> saveLanguage(String code) => _write(_keyLanguage, code);
  Future<String> getLanguage() async => (await _read(_keyLanguage)) ?? 'en';

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() async {
    _mem.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
