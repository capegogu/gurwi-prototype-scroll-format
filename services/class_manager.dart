// lib/services/class_manager.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ClassManager {
  static ClassManager? _instance;
  final _supabase = Supabase.instance.client;

  // Singleton
  ClassManager._();

  static ClassManager getInstance() {
    _instance ??= ClassManager._();
    return _instance!;
  }

  // Cargar idiomas disponibles para una clase
  Future<List<String>> getAvailableLanguages(String classId) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('languages')
          .eq('id_class', classId)
          .single();
      
      return List<String>.from(response['languages'] ?? ['es']);
    } catch (e) {
      print('Error cargando idiomas: $e');
      return ['es']; // Retorna español por defecto en caso de error
    }
  }

  // Cargar contenido de la clase en un idioma específico
  Future<Map<String, dynamic>?> getClassContent({
    required String classId,
    required String language,
  }) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('content_$language')
          .eq('id_class', classId)
          .single();

      return response['content_$language'];
    } catch (e) {
      print('Error cargando contenido: $e');
      return null;
    }
  }

  // Verificar si existe una clase
  Future<bool> classExists(String classId) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('id_class')
          .eq('id_class', classId)
          .single();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Obtener metadatos de la clase
  Future<ClassMetadata?> getClassMetadata(String classId) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('course_title, class_title, class_number')
          .eq('id_class', classId)
          .single();
      
      return ClassMetadata(
        courseTitle: response['course_title'] ?? '',
        classTitle: response['class_title'] ?? '',
        classNumber: response['class_number'] ?? 0,
      );
    } catch (e) {
      print('Error cargando metadatos: $e');
      return null;
    }
  }

  // Reportar error en el contenido
  Future<void> reportContentError({
    required String classId,
    required String language,
    required String errorDescription,
    String? pageNumber,
    String? contentType,
  }) async {
    try {
      await _supabase.from('content_errors').insert({
        'class_id': classId,
        'language': language,
        'error_description': errorDescription,
        'page_number': pageNumber,
        'content_type': contentType,
        'reported_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error reportando error de contenido: $e');
    }
  }

  // Registrar progreso del usuario (si tienes autenticación)
  Future<void> trackProgress({
    required String classId,
    required int pageNumber,
    required String language,
    int? timeSpent,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_progress').upsert({
        'user_id': userId,
        'class_id': classId,
        'page_number': pageNumber,
        'language': language,
        'time_spent': timeSpent,
        'last_accessed': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, class_id');
    } catch (e) {
      print('Error registrando progreso: $e');
    }
  }

  // Obtener recursos asociados a la clase
  Future<List<String>> getClassResources(String classId) async {
    try {
      final response = await _supabase
          .from('class_resources')
          .select('resource_url')
          .eq('class_id', classId);
      
      return List<String>.from(
        response.map((resource) => resource['resource_url'] as String)
      );
    } catch (e) {
      print('Error cargando recursos: $e');
      return [];
    }
  }

  // Verificar si hay actualizaciones de contenido
  Future<bool> hasContentUpdates({
    required String classId,
    required String currentVersion,
  }) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('version')
          .eq('id_class', classId)
          .single();
      
      return response['version'] != currentVersion;
    } catch (e) {
      return false;
    }
  }
}

// Modelo para metadatos de la clase
class ClassMetadata {
  final String courseTitle;
  final String classTitle;
  final int classNumber;

  ClassMetadata({
    required this.courseTitle,
    required this.classTitle,
    required this.classNumber,
  });
}