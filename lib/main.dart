import 'package:flutter/material.dart';
import 'screens/all_screens.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AuthorizationScreen(),
    );
    // return MaterialApp(
    //   home: FillProfileInfoScreen(),
    // );
  }
}