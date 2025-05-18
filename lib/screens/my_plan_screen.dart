import 'package:flutter/material.dart';
import 'predefined_levels_screen.dart';
import 'running_tracker_screen.dart';
import 'weekly_plan_days_screen.dart';

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
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _customFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.7, curve: Curves.easeIn)),
    );
    _runFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My plan'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;

          return SingleChildScrollView(
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
                        BoxShadow(
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                          color: Theme.of(context).shadowColor,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.event_note, size: 64),
                  ),
                ),
                const SizedBox(height: 32),

                Wrap(
                  spacing: 20,
                  runSpacing: 24,
                  children: [
                    // Prepared plan
                    SizedBox(
                      width: isTablet ? (constraints.maxWidth - 60) / 2 : double.infinity,
                      child: FadeTransition(
                        opacity: _preparedFade,
                        child: Semantics(
                          button: true,
                          label: 'Choose a prepared workout plan',
                          child: ElevatedButton.icon(
                            style: _buttonStyle(),
                            icon: const Icon(Icons.fitness_center, size: 28),
                            label: Text(
                              'Choose a Prepared Workout Plan',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    ),

                    // Custom plan
                    SizedBox(
                      width: isTablet ? (constraints.maxWidth - 60) / 2 : double.infinity,
                      child: FadeTransition(
                        opacity: _customFade,
                        child: Semantics(
                          button: true,
                          label: 'Create my own workout plan',
                          child: ElevatedButton.icon(
                            style: _buttonStyle(),
                            icon: const Icon(Icons.edit_note, size: 28),
                            label: Text(
                              'Create My Own Plan',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const WeeklyPlanDaysScreen()),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Go for a run
                    SizedBox(
                      width: isTablet ? (constraints.maxWidth - 60) / 2 : double.infinity,
                      child: FadeTransition(
                        opacity: _runFade,
                        child: Semantics(
                          button: true,
                          label: 'Go for a run',
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RunningTrackerScreen()),
                              );
                            },
                            child: Container(
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.directions_run, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Go for a run',
                                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
