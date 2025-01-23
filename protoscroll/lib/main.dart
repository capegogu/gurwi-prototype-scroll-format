import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/class_view.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase (reemplaza con tus credenciales)
  await Supabase.initialize(
    url: 'https://fmisaxptrmrtjqadqfab.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZtaXNheHB0cm1ydGpxYWRxZmFiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTcyNDg2ODAsImV4cCI6MjAzMjgyNDY4MH0.fseP_d80V-wDS3HobYhuWAqdBQ2DP2hPe8uQEG2WTOY',
  );
  
  // Inicializar PreferencesService
  await PreferencesService.getInstance();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String classId = '94b31dbf-875c-40cc-a221-c512b68b01cf';
    
    return MaterialApp(
      title: 'Visualizador de Clase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF7C325),
          brightness: Brightness.dark,
        ),
      ),
      home: const ClassView(
        classId: classId,
        initialLanguage: 'es', // Idioma por defecto
      ),
    );
  }
} 