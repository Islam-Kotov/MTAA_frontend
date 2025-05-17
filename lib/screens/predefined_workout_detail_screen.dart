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
        'http://192.168.1.36:8000/api/predefined-workouts/${widget.workoutId}');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          workout = jsonDecode(response.body);
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

  void _showFullscreen(String content, {bool isImage = false}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: isImage
            ? InteractiveViewer(
          child: Image.network(content, fit: BoxFit.contain),
        )
            : Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workout == null
          ? const Center(child: Text('Workout not found'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workout!['title'],
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              workout!['focus'] ?? '',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 24),
            _infoBlock(),
            const SizedBox(height: 28),
            const Text(
              'Benefits:',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () =>
                  _showFullscreen(workout!['benefits'] ?? ''),
              child: Text(
                workout!['benefits'] ?? '',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 36),
            const Text(
              'Exercises:',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._buildExercisesList(workout!['exercises']),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _infoRow('Duration:', workout!['duration']),
          _infoRow('Calories:', workout!['calories']),
          _infoRow('Sets/Reps:', workout!['sets_reps']),
          _infoRow('Rest:', workout!['rest']),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value ?? '-',
                style: const TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExercisesList(List exercises) {
    return exercises.map<Widget>((exercise) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise['image'] != null)
              GestureDetector(
                onTap: () =>
                    _showFullscreen(exercise['image'], isImage: true),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    exercise['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(),
                  ),
                ),
              )
            else
              _fallbackIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise['name'] ?? 'Unnamed',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(exercise['reps_sets'] ?? '-',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () =>
                        _showFullscreen(exercise['description'] ?? ''),
                    child: Text(exercise['description'] ?? '',
                        style: const TextStyle(fontSize: 18)),
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
    width: 80,
    height: 80,
    color: Colors.grey.shade200,
  );
}
