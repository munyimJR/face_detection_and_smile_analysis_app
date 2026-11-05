import 'package:flutter/material.dart';
import 'theme/theme_notifier.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FaceDetectionApp());
}

class FaceDetectionApp extends StatelessWidget {
  const FaceDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF4F46E5); // Modern Indigo

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Face Detection & Smile Analysis',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
              surface: const Color(0xFFF8FAFC),
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: seedColor,
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
              surface: const Color(0xFF0F172A),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: seedColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
