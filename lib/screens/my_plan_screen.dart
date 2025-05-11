import 'package:flutter/material.dart';
import 'predefined_levels_screen.dart';
import 'my_own_plan_screen.dart';

class MyPlanScreen extends StatefulWidget {
  const MyPlanScreen({super.key});

  @override
  State<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends State<MyPlanScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _preparedFade;
  late Animation<double> _customFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _preparedFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _customFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            FadeTransition(
              opacity: _preparedFade,
              child: ElevatedButton.icon(
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
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _customFade,
              child: ElevatedButton.icon(
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
            ),
          ],
        ),
      ),
    );
  }
}
