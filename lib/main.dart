import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/colors.dart';
import 'presentation/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROTA Accounting',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.canvasBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.electricCyan,
          secondary: AppColors.neonMint,
          surface: AppColors.cardSurface,
          background: AppColors.canvasBackground,
          error: AppColors.laserCoral,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}
