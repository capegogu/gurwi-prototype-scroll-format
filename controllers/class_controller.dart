// lib/controllers/class_controller.dart

import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ClassController extends ChangeNotifier {
  final String classId;
  final _supabase = Supabase.instance.client;
  final PreferencesService _preferences;

  // Estado
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _classContent;
  int _currentPage = 0;
  String _currentLanguage = 'es';
  List<String> _availableLanguages = ['es'];

  // Agregar nuevas variables de estado
  String? _courseTitle;
  String? _classTitle;
  int? _classNumber;
  String? _path;
  bool _isFree = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  int get currentPage => _currentPage;
  String get currentLanguage => _currentLanguage;
  List<String> get availableLanguages => _availableLanguages;
  int get totalPages => (_classContent?['pages']?.length ?? 2) - 2;
  double get progressValue => totalPages > 0 ? _currentPage / totalPages : 0;
  bool get isLastPage => _currentPage >= totalPages;
  
  String get courseTitle => _courseTitle ?? '';
  String get classTitle => _classTitle ?? '';
  int get classNumber => _classNumber ?? 0;
  String get path => _path ?? '';
  bool get isFree => _isFree;

  bool get isQuestionPage {
    final pageContent = getCurrentPageContent();
    return pageContent?.any((content) => content['type'] == 'question') ?? false;
  }

  ClassController(
    this.classId, {
    required PreferencesService preferences,
    String? initialLanguage,
  }) : _preferences = preferences {
    if (initialLanguage != null) {
      _currentLanguage = initialLanguage;
    }
    _initializeClass();
  }

  Future<void> _initializeClass() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Cargar idiomas disponibles y contenido
      await _loadAvailableLanguages();
      await _loadContent();

      // Inicializar en página 1
      _currentPage = 1;
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar la clase: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final response = await _supabase
          .from('classes')
          .select('''
            languages,
            path,
            is_free,
            title_es,
            title_en,
            title_pt,
            unit_id,
            formation_id
          ''')
          .eq('id_class', classId)
          .single();

      // Cargar idiomas disponibles
      _availableLanguages = List<String>.from(response['languages'] ?? ['es']);
      
      // Cargar metadatos de la clase
      _path = response['path'];
      _isFree = response['is_free'] ?? false;
      
      // Cargar título según el idioma actual
      _updateTitles(response);

      // Asegurar que el idioma actual esté disponible
      if (!_availableLanguages.contains(_currentLanguage)) {
        _currentLanguage = _availableLanguages.first;
      }
    } catch (e) {
      print('Error loading class metadata: $e');
      _availableLanguages = ['es'];
      rethrow;
    }
  }

  void _updateTitles(Map<String, dynamic> response) {
    // Actualizar títulos según el idioma actual
    _classTitle = response['title_$_currentLanguage'];
    
    // Si no existe el título en el idioma actual, usar español como fallback
    _classTitle ??= response['title_es'];
    
    // También podemos actualizar otros títulos si es necesario
    _courseTitle = _classContent?['course_title'];
  }

  Future<void> _loadContent() async {
    try {
      final response = await _supabase
          .from('classes')
          .select('content_$_currentLanguage')
          .eq('id_class', classId)
          .single();

      final content = response['content_$_currentLanguage'];
      
      if (content == null) {
        throw Exception('No se encontró contenido para el idioma $_currentLanguage');
      }

      // Parsear el contenido JSON
      _classContent = content;
      
      // Extraer información adicional del contenido
      if (_classContent != null) {
        _courseTitle = _classContent!['course_title'];
        _classNumber = _classContent!['class_number'];
      }
    } catch (e) {
      throw Exception('Error cargando contenido: $e');
    }
  }

  Future<void> changeLanguage(String newLanguage) async {
    if (_currentLanguage == newLanguage) return;
    
    try {
      final previousLanguage = _currentLanguage;
      final previousContent = _classContent;
      
      try {
        // Cargar el contenido del nuevo idioma
        final response = await _supabase
            .from('classes')
            .select('''
              content_$newLanguage,
              title_$newLanguage
            ''')
            .eq('id_class', classId)
            .single();

        final content = response['content_$newLanguage'];
        
        if (content == null) {
          throw Exception('No se encontró contenido para el idioma $newLanguage');
        }

        // Actualizar el idioma y el contenido
        _currentLanguage = newLanguage;
        
        // Parsear el contenido JSON si es necesario
        _classContent = content is String ? jsonDecode(content) : content;
        
        // Actualizar todos los datos relacionados
        if (_classContent != null) {
          _courseTitle = _classContent!['course_title'];
          _classTitle = _classContent!['class_title'];
          _classNumber = _classContent!['class_number'];
        }

        // Guardar la preferencia de idioma
        await _preferences.saveClassProgress(
          classId: classId,
          currentPage: _currentPage,
          language: newLanguage,
        );

        // Notificar a los widgets que deben actualizarse
        notifyListeners();

      } catch (e) {
        // Revertir cambios en caso de error
        _currentLanguage = previousLanguage;
        _classContent = previousContent;
        rethrow;
      }
    } catch (e) {
      print('Error changing language: $e');
      _error = 'Error al cambiar el idioma: $e';
      notifyListeners();
    }
  }

  Future<void> changePage(int newPage) async {
    if (newPage < 0 || newPage >= totalPages || _currentPage == newPage) {
      return;
    }

    _currentPage = newPage;
    await _saveProgress();
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    await _preferences.saveClassProgress(
      classId: classId,
      currentPage: _currentPage,
      language: _currentLanguage,
    );
  }

  List<dynamic>? getCurrentPageContent() {
    if (_classContent == null || _currentPage >= totalPages) {
      return null;
    }
    // Ajustar el índice sumando 1 para omitir la página 0
    return _classContent!['pages'][_currentPage + 1]['content'];
  }

  Future<void> retryLoading() async {
    _error = null;
    await _initializeClass();
  }

  // Navegar a la siguiente página
  Future<void> nextPage() async {
    if (!isLastPage) {
      await changePage(_currentPage + 1);
    }
  }

  // Navegar a la página anterior
  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await changePage(_currentPage - 1);
    }
  }

  // Reiniciar progreso
  Future<void> resetProgress() async {
    await _preferences.resetClassProgress(classId);
    _currentPage = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  List<dynamic>? getPageContent(int pageIndex) {
    try {
      if (_classContent == null) return null;
      
      final pages = _classContent!['pages'] as List;
      
      // Verificamos que el índice sea válido y mayor que 0
      if (pageIndex <= 0 || pageIndex >= pages.length) {
        return null;
      }
      
      // Buscamos la página específica en el array
      final page = pages.firstWhere(
        (page) => page['page_number'] == pageIndex,
        orElse: () => null,
      );
      
      return page?['content'];
    } catch (e) {
      print('Error getting page content: $e');
      return null;
    }
  }

  // Agregar método para verificar si un idioma está disponible
  bool isLanguageAvailable(String language) {
    return _availableLanguages.contains(language);
  }

  // Agregar método para obtener el título en un idioma específico
  Future<String?> getTitleInLanguage(String language) async {
    try {
      final response = await _supabase
          .from('classes')
          .select('title_$language')
          .eq('id_class', classId)
          .single();
      return response['title_$language'];
    } catch (e) {
      print('Error getting title in $language: $e');
      return null;
    }
  }
}