
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CaminhadasApp());
}

class CaminhadasApp extends StatefulWidget {
  const CaminhadasApp({super.key});

  @override
  State<CaminhadasApp> createState() => _CaminhadasAppState();
}

class _CaminhadasAppState extends State<CaminhadasApp> {
  bool temaEscuro = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caminhadas',
      themeMode: temaEscuro ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF32856E),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF65C9A8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(
        aoAlterarTema: () {
          setState(() => temaEscuro = !temaEscuro);
        },
        temaEscuro: temaEscuro,
      ),
    );
  }
}