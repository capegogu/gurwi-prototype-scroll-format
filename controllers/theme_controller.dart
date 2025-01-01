// lib/controllers/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;
  late ThemeMode _themeMode;

  ThemeController(this._prefs) {
    // Cargar preferencia guardada o usar el tema del sistema por defecto
    _themeMode = _loadThemeMode();
  }

  // Getter para el modo de tema actual
  ThemeMode get themeMode => _themeMode;

  // Getter para saber si está en modo oscuro
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Cargar el modo de tema guardado
  ThemeMode _loadThemeMode() {
    final savedMode = _prefs.getString(_themeKey);
    switch (savedMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Cambiar el modo de tema
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    String? valueToSave;
    
    switch (mode) {
      case ThemeMode.light:
        valueToSave = 'light';
        break;
      case ThemeMode.dark:
        valueToSave = 'dark';
        break;
      case ThemeMode.system:
        valueToSave = null;
        break;
    }

    if (valueToSave != null) {
      await _prefs.setString(_themeKey, valueToSave);
    } else {
      await _prefs.remove(_themeKey);
    }

    notifyListeners();
  }

  // Alternar entre modo claro y oscuro
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Paleta de colores para modo claro
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFFF7C325),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFF7C325),
        secondary: Colors.orange[800]!,
        surface: Colors.white,
        error: Colors.red[700]!,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(color: Colors.black),
      ),
      dividerColor: Colors.grey[300],
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7C325),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Paleta de colores para modo oscuro
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFF7C325),
      scaffoldBackgroundColor: const Color(0xFF0A0A14),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A0A14),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFF7C325),
        secondary: Colors.orange[800]!,
        surface: const Color(0xFF1C1C28),
        error: Colors.red[700]!,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
      ),
      dividerColor: Colors.white12,
      cardTheme: CardTheme(
        color: const Color(0xFF1C1C28),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7C325),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF1C1C28),
        textStyle: TextStyle(color: Colors.white),
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: Color(0xFF1C1C28),
        titleTextStyle: TextStyle(color: Colors.white),
        contentTextStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  // Obtener el tema actual basado en el modo
  ThemeData getTheme(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark
          ? darkTheme
          : lightTheme;
    }
    return _themeMode == ThemeMode.dark ? darkTheme : lightTheme;
  }
}

// Extensión para acceder fácilmente al tema desde cualquier widget
extension ThemeExtension on BuildContext {
  ThemeController get themeController => Provider.of<ThemeController>(this, listen: false);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}