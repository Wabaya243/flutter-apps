import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_service.dart';

// Point d'entrée: charge l'état de connexion avant de lancer l'app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authService.loadToken();
  runApp(AcademiaChatbotApp(isLoggedIn: authService.isLoggedIn));
}

class AcademiaChatbotApp extends StatelessWidget {
  final bool isLoggedIn;
  const AcademiaChatbotApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.lightBlueAccent,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academia Chatbot',
      theme: base.copyWith(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: const Color(0xFF0D0D0D),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: base.textTheme.apply(
          fontFamily: 'Roboto',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          hintStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      // Utilise la route selon l'état de connexion
      initialRoute: isLoggedIn ? '/home' : '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/home': (_) => const HomePage(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

