import 'package:flutter/material.dart';
import 'predefined_levels_screen.dart';
import 'my_own_plan_screen.dart';

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
        child: Column(
          children: [
            ElevatedButton.icon(
              style: _buttonStyle(),
              icon: const Icon(Icons.fitness_center, size: 28, color: Colors.black87),
              label: const Text(
                'Choose a Prepared Workout Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PredefinedLevelsScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: _buttonStyle(),
              icon: const Icon(Icons.edit_note, size: 28, color: Colors.black87),
              label: const Text(
                'Create My Own Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyOwnPlanScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(double.infinity, 80),
      elevation: 5,
    );
  }
}
