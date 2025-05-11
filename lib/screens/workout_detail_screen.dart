import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class WorkoutDetailScreen extends StatelessWidget {
  final int workoutId;
  final String heroTag;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
    required this.heroTag,
  });

  Future<Map?> fetchWorkout() async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/workouts/$workoutId');
    log('📡 Fetching workout details from: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('❌ Workout not found: ${response.statusCode}', error: response.body);
        return null;
      }
    } catch (e) {
      log('❗ Exception while loading workout', error: e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercise Detail"),
      ),
      body: FutureBuilder<Map?>(
        future: fetchWorkout(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final workout = snapshot.data;

          if (workout == null) {
            return const Center(
              child: Text(
                'Exercise not found or error loading data.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (workout['exercise_photo'] != null)
                  GestureDetector(
                    onTap: () {
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'ImageZoom',
                        barrierColor: Colors.black.withAlpha(240), // почти черный
                        transitionDuration: const Duration(milliseconds: 200),
                        pageBuilder: (_, __, ___) => GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Scaffold(
                            backgroundColor: Colors.transparent,
                            body: Center(
                              child: Hero(
                                tag: heroTag,
                                child: InteractiveViewer(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      workout['exercise_photo'],
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 220,
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: Icon(Icons.broken_image, size: 60),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: heroTag,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              // color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            workout['exercise_photo'],
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 220,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                Text(
                  workout['exercise_name'] ?? 'Unnamed',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 24),

                _infoCard(
                  icon: Icons.fitness_center_outlined,
                  label: 'Target Muscles',
                  value: workout['main_muscles'] ?? 'N/A',
                ),
                const SizedBox(height: 14),

                _infoCard(
                  icon: Icons.build_outlined,
                  label: 'Equipment Required',
                  value: workout['equipment_req'] ?? 'N/A',
                ),
                const SizedBox(height: 14),

                _infoCard(
                  icon: Icons.description_outlined,
                  label: 'Execution Guide',
                  value: workout['execution_guide'] ?? 'N/A',
                  multiline: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
