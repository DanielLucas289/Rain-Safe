// ARQUIVO: lib/main.dart (versão com Firebase)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'package:weather/weather.dart';

// A função 'main' agora é 'async' para poder esperar o Firebase inicializar
void main() async {
  // Essas duas linhas são necessárias para garantir que o Firebase inicialize
  // antes de o aplicativo rodar.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RainSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData( // Seu tema continua aqui, sem alterações...
        primaryColor: Colors.lightBlueAccent,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.lightBlueAccent,
          elevation: 0,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.lightBlueAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.amberAccent),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.lightBlueAccent,
          unselectedItemColor: Colors.black54,
        ),
      ),
      // AQUI ESTÁ A MUDANÇA PRINCIPAL:
      // Usamos um StreamBuilder para ser o "porteiro" do nosso app.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Se o snapshot tem dados, o usuário está LOGADO.
          if (snapshot.hasData) {
            return const HomeScreen(); // Mostra a tela principal
          }
          // Se não, o usuário está DESLOGADO.
          return AuthScreen(); // Mostra a tela de login/cadastro
        },
      ),
    );
  }
}