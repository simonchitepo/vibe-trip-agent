import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: VibeTripApp()));
}

class VibeTripApp extends StatelessWidget {
  const VibeTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true, colorScheme: AppTheme.scheme);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Vibe Trip Agent',
      theme: base.copyWith(
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
        scaffoldBackgroundColor: AppTheme.scheme.surface,
      ),
      routerConfig: appRouter,
    );
  }
}
