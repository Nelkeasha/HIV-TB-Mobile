import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

class LanguageNotifier extends StateNotifier<String> {
  final SecureStorage _storage;

  LanguageNotifier(this._storage) : super('en') {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.getLanguage();
  }

  Future<void> setLanguage(String code) async {
    state = code;
    await _storage.saveLanguage(code);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref.read(secureStorageProvider));
});
