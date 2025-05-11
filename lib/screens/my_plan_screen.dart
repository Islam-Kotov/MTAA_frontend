import 'package:flutter/material.dart';
import 'predefined_levels_screen.dart';
import 'my_own_plan_screen.dart';
import 'running_tracker_screen.dart';

class MyPlanScreen extends StatefulWidget {
  const MyPlanScreen({super.key});

  @override
  State<MyPlanScreen> createState() => _MyPlanScreenState();
}

class _MyPlanScreenState extends State<MyPlanScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _preparedFade;
  late Animation<double> _customFade;
  late Animation<double> _runFade;

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
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _customFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    _runFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(double.infinity, 80),
      elevation: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: colors.primary ),
                  ],
                ),
                child: const Icon(Icons.event_note, size: 64),
              ),
            ),
            const SizedBox(height: 32),

            // 🏋️ Prepared plan
            FadeTransition(
              opacity: _preparedFade,
              child: ElevatedButton.icon(
                style: _buttonStyle(),
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
            const SizedBox(height: 24),

            // ✏️ Custom plan
            FadeTransition(
              opacity: _customFade,
              child: ElevatedButton.icon(
                style: _buttonStyle(),
                icon: const Icon(Icons.edit_note, size: 28),
                label: const Text(
                  'Create My Own Plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyOwnPlanScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // 🏃‍♂️ Квадратная кнопка Go for a run (слева)
            FadeTransition(
              opacity: _runFade,
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RunningTrackerScreen()),
                    );
                  },
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_run, size: 40),
                        SizedBox(height: 10),
                        Text(
                          'Go for a run',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
