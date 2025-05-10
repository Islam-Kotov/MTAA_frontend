import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WorkoutsListScreen extends StatefulWidget {
  final String categoryName;

  const WorkoutsListScreen({super.key, required this.categoryName});

  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen> {
  List workouts = [];

  @override
  void initState() {
    super.initState();
    fetchWorkouts();
  }

  Future<void> fetchWorkouts() async {
    final uri = Uri.parse(
        'http://192.168.1.36:8000/api/workouts?category=${Uri.encodeComponent(widget.categoryName)}');
    print('Fetching workouts from: $uri'); // логируем URL

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      print('Response OK');
      final data = jsonDecode(response.body);
      for (var workout in data) {
        print('Workout: ${workout['exercise_name']}');
        print('Image URL: ${workout['exercise_photo']}');
      }

      setState(() {
        workouts = data;
      });
    } else {
      print('Error loading workouts: ${response.statusCode}');
      print('Server response: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      body: workouts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          final imageUrl = workout['exercise_photo'];

          return ListTile(
            leading: imageUrl != null
                ? SizedBox(
              width: 60,
              height: 60,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading the image: $imageUrl');
                  print('Error: $error');
                  return const Icon(Icons.broken_image);
                },
              ),
            )
                : const Icon(Icons.image_not_supported),
            title: Text(workout['exercise_name'] ?? 'No name'),
            subtitle: Text(workout['exercise_type'] ?? ''),
            onTap: () {
              print('Tapped workout: ${workout['id']}');
            },
          );
        },
      ),
    );
  }
}
