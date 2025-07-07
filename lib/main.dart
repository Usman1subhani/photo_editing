import 'package:cropmeapp/Screens/homeScreen.dart';
import 'package:cropmeapp/Screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'CropMe - Social Media Image Resizer',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
              brightness: Brightness.dark,
              primary: const Color(0xFFB69DF8),
              secondary: const Color(0xFF03DAC6),
              background: const Color(0xFF181824),
              surface: const Color(0xFF232336),
              onPrimary: Colors.white,
              onSecondary: Colors.black,
              onBackground: Colors.white,
              onSurface: Colors.white,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF232336),
              foregroundColor: Color(0xFFB69DF8),
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Color(0xFFB69DF8),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              iconTheme: IconThemeData(color: Color(0xFFB69DF8)),
            ),
            cardTheme: CardTheme(
              color: const Color(0xFF232336),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB69DF8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB69DF8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB69DF8), width: 2),
              ),
            ),
          ),
          themeMode: ThemeMode.system,
          home: const SplashScreen(),
        );
      },
    );
  }
}
