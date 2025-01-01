// lib/services/preferences_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _prefKeyPrefix = 'class_progress_';
  static const String _prefLanguageKey = 'preferred_language';
  static PreferencesService? _instance;
  late SharedPreferences _prefs;

  // Constructor privado
  PreferencesService._();

  // Singleton
  static Future<PreferencesService> getInstance() async {
    if (_instance == null) {
      _instance = PreferencesService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Guardar progreso de la clase
  Future<void> saveClassProgress({
    required String classId,
    required int currentPage,
    required String language,
  }) async {
    await _prefs.setInt('$_prefKeyPrefix${classId}_page', currentPage);
    await _prefs.setString('$_prefKeyPrefix${classId}_lang', language);
  }

  // Obtener progreso guardado
  Future<ClassProgress?> getClassProgress(String classId) async {
    final currentPage = _prefs.getInt('$_prefKeyPrefix${classId}_page');
    final language = _prefs.getString('$_prefKeyPrefix${classId}_lang');

    if (currentPage == null || language == null) {
      return null;
    }

    return ClassProgress(
      currentPage: currentPage,
      language: language,
    );
  }

  // Reiniciar progreso
  Future<void> resetClassProgress(String classId) async {
    await _prefs.remove('$_prefKeyPrefix${classId}_page');
    await _prefs.remove('$_prefKeyPrefix${classId}_lang');
  }

  // Guardar idioma preferido
  Future<void> setPreferredLanguage(String language) async {
    await _prefs.setString(_prefLanguageKey, language);
  }

  // Obtener idioma preferido
  Future<String?> getPreferredLanguage() async {
    return _prefs.getString(_prefLanguageKey);
  }
}

class ClassProgress {
  final int currentPage;
  final String language;

  ClassProgress({
    required this.currentPage,
    required this.language,
  });
}