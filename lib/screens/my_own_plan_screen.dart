import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer';

import 'workouts_list_screen.dart'; // <-- подключаем список упражнений

class MyOwnPlanScreen extends StatefulWidget {
  const MyOwnPlanScreen({super.key});

  @override
  State<MyOwnPlanScreen> createState() => _MyOwnPlanScreenState();
}

class _MyOwnPlanScreenState extends State<MyOwnPlanScreen> {
  List<dynamic> exercises = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPlan();
  }

  Future<void> fetchPlan() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token'); // исправлено имя ключа

    if (token == null) {
      log('❌ No token found');
      setState(() => isLoading = false);
      return;
    }

    final uri = Uri.parse('http://192.168.1.36:8000/api/plan');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        exercises = data;
        isLoading = false;
      });
    } else {
      log('❌ Failed to fetch plan: ${response.statusCode}');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('My Custom Plan'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
          ? const Center(
        child: Text(
          'Your custom workout plan is empty.\nTap the + button to add exercises.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      )
          : ListView.builder(
        itemCount: exercises.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = exercises[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
            child: ListTile(
              title: Text(item['exercise_name']),
              subtitle: Text(
                'Sets: ${item['sets']}, Reps: ${item['repetitions']}',
              ),
              trailing: const Icon(Icons.fitness_center),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
        onPressed: () async {
          // Навигация к списку упражнений
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WorkoutsListScreen(categoryName: 'Weight Training'),
            ),
          );
          // После возвращения обновляем список
          fetchPlan();
        },
        icon: const Icon(Icons.add, size: 30),
        label: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Add Exercises',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
