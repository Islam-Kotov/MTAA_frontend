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
        'http://147.175.162.111:8000/api/predefined-workouts/${widget.workoutId}');
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
            color: Theme.of(context).dialogBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 22),
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
          : LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 700 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout!['title'],
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      workout!['focus'] ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 24),
                    _infoBlock(),
                    const SizedBox(height: 28),
                    Text(
                      'Benefits:',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showFullscreen(workout!['benefits'] ?? ''),
                      child: Text(
                        workout!['benefits'] ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Exercises:',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._buildExercisesList(workout!['exercises']),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoBlock() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: kElevationToShadow[1],
      ),
      child: Column(
        children: [
          _infoRow('Duration:', workout!['duration'], textColor),
          _infoRow('Calories:', workout!['calories'], textColor),
          _infoRow('Sets/Reps:', workout!['sets_reps'], textColor),
          _infoRow('Rest:', workout!['rest'], textColor),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value, Color? textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value ?? '-', style: TextStyle(fontSize: 20, color: textColor)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExercisesList(List exercises) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return exercises.map<Widget>((exercise) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: kElevationToShadow[2],
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
                  Text(
                    exercise['name'] ?? 'Unnamed',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  Text(
                    exercise['reps_sets'] ?? '-',
                    style: TextStyle(fontSize: 18, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () =>
                        _showFullscreen(exercise['description'] ?? ''),
                    child: Text(
                      exercise['description'] ?? '',
                      style: TextStyle(fontSize: 18, color: textColor),
                    ),
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
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.broken_image, color: Colors.black54),
  );
}
