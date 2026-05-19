import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/main_page.dart'; // ← mudou o import

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leviathan Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050508),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BFFF),
          secondary: Color(0xFF1A5F8A),
          surface: Color(0xFF0D1117),
        ),
        textTheme: GoogleFonts.shareTechMonoTextTheme(
          ThemeData.dark().textTheme,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF0D1117),
          contentTextStyle: TextStyle(color: Color(0xFF00BFFF)),
        ),
      ),
      home: const MainPage(), // ← mudou o home
    );
  }
}