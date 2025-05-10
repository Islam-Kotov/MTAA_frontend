import 'package:flutter/material.dart';
import 'predefined_levels_screen.dart';

class MyPlanScreen extends StatelessWidget {
  const MyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('My plan'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size(double.infinity, 80),
              elevation: 5,
            ),
            icon: const Icon(Icons.fitness_center, size: 28),
            label: const Text(
              'Choose a Prepared Workout Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PredefinedLevelsScreen()),
              );
            },
          ),
        ),
      ),
    );
  }
}
