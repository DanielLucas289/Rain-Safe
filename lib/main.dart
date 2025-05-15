import 'package:flutter/material.dart';
import 'screens/home_screen.dart';          // ✅ Use HomeScreen instead of initialRoute
import 'theme/app_colors.dart';            // ✅ Custom colors

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RainSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.lightBlueAccent, // Azul claro
        scaffoldBackgroundColor: Colors.white, // Fundo branco
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
            borderSide: BorderSide(color: Colors.amberAccent), // foco amarelo
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amberAccent, // Amarelo claro
            foregroundColor: Colors.black, // texto escuro
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

      home: const HomeScreen(), // ✅ Now using HomeScreen with bottom nav
    );
  }
}
