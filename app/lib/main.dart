import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service (cookies, storage)
  await ApiService().init();
  
  runApp(const ArchanaComputersApp());
}

class ArchanaComputersApp extends StatelessWidget {
  const ArchanaComputersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Archana Computers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D1B3E)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
