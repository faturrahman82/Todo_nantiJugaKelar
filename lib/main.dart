import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'ui/pages/home_page.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await NotificationService().init();
  runApp(const NantiJugaKelarApp());
}

class NantiJugaKelarApp extends StatefulWidget {
  const NantiJugaKelarApp({super.key});

  @override
  State<NantiJugaKelarApp> createState() => _NantiJugaKelarAppState();

  // Static method to access the state and toggle theme
  static _NantiJugaKelarAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_NantiJugaKelarAppState>();
}

class _NantiJugaKelarAppState extends State<NantiJugaKelarApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NantiJugaKelar - Daftar Tugas',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF111827),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111827),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF3B82F6),
          primary: const Color(0xFF3B82F6),
          surface: const Color(0xFF1F2937),
          onSurface: const Color(0xFFF9FAFB),
        ),
      ),
      home: const HomePage(),
    );
  }
}
