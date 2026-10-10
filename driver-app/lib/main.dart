import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'screens/login_screen.dart';

void main() {
  ApiConfig.validate();
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: LoginScreen(),
    );
  }
}
