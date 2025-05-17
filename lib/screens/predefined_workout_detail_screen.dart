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
  State<PredefinedWorkoutDetailScreen> createState() => _PredefinedWorkoutDetailScreenState();
}

class _PredefinedWorkoutDetailScreenState extends State<PredefinedWorkoutDetailScreen> {
  Map? workout;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchWorkoutDetail();
  }

  Future<void> fetchWorkoutDetail() async {
    setState(() => isLoading = true);
    final uri = Uri.parse('http://192.168.1.36:8000/api/predefined-workouts/${widget.workoutId}');
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontSize: 18),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _showFullscreen(widget.imageUrl, isImage: true),
              child: Hero(
                tag: 'predefined-workout-image-${widget.workoutId}',
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    image: DecorationImage(
                      image: NetworkImage(widget.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              workout!['title'],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              workout!['focus'] ?? '',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            _infoBlock(),
            const SizedBox(height: 24),
            const Text('💪 Benefits:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullscreen(workout!['benefits'] ?? ''),
              child: Text(
                workout!['benefits'] ?? '',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
            const Text('📋 Exercises:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._buildExercisesList(workout!['exercises']),
          ],
        ),
      ),
    );
  }

  Widget _infoBlock() {
    return Container(
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 18))),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (exercise['image'] != null) {
                  _showFullscreen(exercise['image'], isImage: true);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: exercise['image'] != null
                    ? Image.network(
                  exercise['image'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(),
                )
                    : _fallbackIcon(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise['name'] ?? 'Unnamed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(exercise['reps_sets'] ?? '-', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showFullscreen(exercise['description'] ?? ''),
                    child: Text(exercise['description'] ?? '', style: const TextStyle(fontSize: 16)),
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
    width: 70,
    height: 70,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported),
  );
}
