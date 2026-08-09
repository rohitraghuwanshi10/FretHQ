import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FretHQApp());
}

class FretHQApp extends StatelessWidget {
  const FretHQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FretHQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121216),
        primarySwatch: Colors.amber,
        fontFamily: GoogleFonts.outfit().fontFamily,
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          surface: const Color(0xFF1E1E26),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
