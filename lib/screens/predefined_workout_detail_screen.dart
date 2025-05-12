import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class PredefinedWorkoutDetailScreen extends StatefulWidget {
  final int workoutId;
  final String imageUrl;

  const PredefinedWorkoutDetailScreen({
    super.key,
    required this.workoutId,
    required this.imageUrl,
  });

  @override
  State<PredefinedWorkoutDetailScreen> createState() =>
      _PredefinedWorkoutDetailScreenState();
}

class _PredefinedWorkoutDetailScreenState
    extends State<PredefinedWorkoutDetailScreen> {
  Map? workout;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWorkoutDetail();
  }

  Future<void> fetchWorkoutDetail() async {
    setState(() => isLoading = true);

    final uri = Uri.parse(
        'http://147.175.163.45:8000/api/predefined-workouts/${widget.workoutId}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          workout = data;
          isLoading = false;
        });
      } else {
        log('Failed to load workout: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      log('Error fetching workout', error: e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workout == null
          ? const Center(child: Text('Workout not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'predefined-workout-image-${widget.workoutId}',
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center,
                    size: 80),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              workout!['title'],
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              workout!['focus'] ?? '',
              style: const TextStyle(
                fontSize: 16
              ),
            ),
            const SizedBox(height: 20),
            _infoBlock(),
            const SizedBox(height: 24),
            const Text(
              '💪 Benefits:',
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              workout!['benefits'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              '📋 Exercises:',
              style:
              TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._buildExercisesList(workout!['exercises']),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock() {
    return Container(
      decoration: BoxDecoration(
        // color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoRow('⏱ Duration:', workout!['duration']),
          _infoRow('🔥 Calories:', workout!['calories']),
          _infoRow('🌀 Sets/Reps:', workout!['sets_reps']),
          _infoRow('😮‍💨 Rest:', workout!['rest']),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExercisesList(List exercises) {
    return exercises.map<Widget>((exercise) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: exercise['image'] != null
                  ? Image.network(
                exercise['image'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackIcon(),
              )
                  : _fallbackIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['name'] ?? 'Unnamed',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    exercise['reps_sets'] ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exercise['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _fallbackIcon() => Container(
    width: 60,
    height: 60,
    child: const Icon(Icons.image_not_supported),
  );
}
