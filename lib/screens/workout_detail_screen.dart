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
    log('Fetching workout details from: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        log('Workout not found: ${response.statusCode}', error: response.body);
        return null;
      }
    } catch (e) {
      log('Exception while loading workout', error: e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(title: const Text("Exercise Detail")),
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
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 800 : double.infinity),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (workout['exercise_photo'] != null)
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Scaffold(
                                backgroundColor: Colors.black.withOpacity(0.95),
                                body: Center(
                                  child: Hero(
                                    tag: heroTag,
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        workout['exercise_photo'],
                                        fit: BoxFit.contain,
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
                                child: const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Text(
                      workout['exercise_name'] ?? 'Unnamed',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 28),

                    _semanticInfoCard(
                      icon: Icons.fitness_center_outlined,
                      label: 'Target Muscles',
                      value: workout['main_muscles'] ?? 'N/A',
                    ),
                    const SizedBox(height: 18),

                    _semanticInfoCard(
                      icon: Icons.build_outlined,
                      label: 'Equipment Required',
                      value: workout['equipment_req'] ?? 'N/A',
                    ),
                    const SizedBox(height: 18),

                    GestureDetector(
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: 'ExecutionGuide',
                          barrierColor: Colors.black.withOpacity(0.85),
                          transitionDuration: const Duration(milliseconds: 250),
                          pageBuilder: (_, __, ___) => Center(
                            child: Material(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    workout['execution_guide'] ?? 'N/A',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: _semanticInfoCard(
                        icon: Icons.description_outlined,
                        label: 'Execution Guide (Tap to Expand)',
                        value: workout['execution_guide'] ?? 'N/A',
                        isClickable: true,
                        multiline: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _semanticInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
    bool isClickable = false,
  }) {
    return Semantics(
      label: '$label: $value',
      button: isClickable,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.black87),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: isClickable ? Colors.black : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}