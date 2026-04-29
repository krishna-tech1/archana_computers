import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
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
        fontFamily: 'Roboto', // Defaulting to Roboto, can be changed later
      ),
      home: const LoginPage(),
    );
  }
}
