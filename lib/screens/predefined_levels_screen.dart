import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

import 'predefined_workout_detail_screen.dart';

class PredefinedLevelsScreen extends StatefulWidget {
  const PredefinedLevelsScreen({super.key});

  @override
  State<PredefinedLevelsScreen> createState() => _PredefinedLevelsScreenState();
}

class _PredefinedLevelsScreenState extends State<PredefinedLevelsScreen> {
  List workouts = [];
  String? selectedLevel;
  bool isLoading = false;
  ColorScheme colors = ThemeData().colorScheme;

  @override
  void initState() {
    super.initState();
    fetchWorkouts('Beginner');
  }

  Future<void> fetchWorkouts(String level) async {
    setState(() {
      isLoading = true;
      selectedLevel = level;
      workouts = [];
    });

    final uri = Uri.parse('http://192.168.1.36:8000/api/predefined-workouts?level=$level');
    log('📡 Fetching $level workouts: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          workouts = data;
        });
      } else {
        log('❌ Failed to load workouts: ${response.statusCode}', error: response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load workouts: ${response.statusCode}')),
        );
      }
    } catch (e) {
      log('❗ Error loading workouts', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading workouts')),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final _colors = Theme.of(context).colorScheme;

    colors = _colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepared Workouts'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _levelButton('Beginner')),
                const SizedBox(width: 12),
                Expanded(child: _levelButton('Advanced')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (selectedLevel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '$selectedLevel Workouts',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isLoading
                  ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              )
                  : workouts.isEmpty
                  ? const Center(
                key: ValueKey('empty'),
                child: Text('No workouts found for this level.'),
              )
                  : ListView.builder(
                key: ValueKey(selectedLevel),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final workout = workouts[index];
                  return WorkoutCard(
                    workout: workout,
                    onTap: () {
                      log('📦 Tapped workout ID: ${workout['id']}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PredefinedWorkoutDetailScreen(
                            workoutId: workout['id'],
                            imageUrl: '', // imageUrl не используется
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelButton(String label) {
    final isActive = selectedLevel == label;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? colors.primary
            : colors.onPrimary,
        foregroundColor: isActive ? Colors.white : Colors.black,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => fetchWorkouts(label),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final Map workout;
  final VoidCallback onTap;

  const WorkoutCard({required this.workout, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 3,
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: Hero(
            tag: 'predefined-workout-image-${workout['id']}',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fitness_center, size: 32, color: Colors.black54),
            ),
          ),
          title: Text(
            workout['title'] ?? 'No title',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${workout['duration']} | ${workout['calories']} | ${workout['exercise_count']} exercises',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
