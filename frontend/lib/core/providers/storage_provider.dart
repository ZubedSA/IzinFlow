import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class LocalAuthStorage {
  final SharedPreferences _prefs;

  LocalAuthStorage(this._prefs);

  Future<void> saveAuthData({
    required String token,
    required String tenantId,
    required String role,
    required String fullName,
    required String email,
  }) async {
    await _prefs.setString('authToken', token);
    await _prefs.setString('tenantId', tenantId);
    await _prefs.setString('userRole', role);
    await _prefs.setString('userFullName', fullName);
    await _prefs.setString('userEmail', email);
  }

  Future<void> clearAuthData() async {
    await _prefs.remove('authToken');
    await _prefs.remove('tenantId');
    await _prefs.remove('userRole');
    await _prefs.remove('userFullName');
    await _prefs.remove('userEmail');
  }

  String? get token => _prefs.getString('authToken');
  String? get tenantId => _prefs.getString('tenantId');
  String? get role => _prefs.getString('userRole');
  String? get fullName => _prefs.getString('userFullName');
  String? get email => _prefs.getString('userEmail');
}

final localAuthStorageProvider = Provider<LocalAuthStorage>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalAuthStorage(prefs);
});
