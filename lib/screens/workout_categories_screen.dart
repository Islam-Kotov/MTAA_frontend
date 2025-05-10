import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'workouts_list_screen.dart'; // Подключаем экран со списком упражнений

class WorkoutCategoriesScreen extends StatefulWidget {
  const WorkoutCategoriesScreen({super.key});

  @override
  State<WorkoutCategoriesScreen> createState() => _WorkoutCategoriesScreenState();
}

class _WorkoutCategoriesScreenState extends State<WorkoutCategoriesScreen> {
  List categories = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final response = await http.get(Uri.parse('http://192.168.1.36:8000/api/categories'));
    if (response.statusCode == 200) {
      setState(() {
        categories = jsonDecode(response.body);
      });
    } else {
      print('Ошибка загрузки категорий: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('Workout Categories'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
      ),
      body: categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              leading: const Icon(Icons.fitness_center, size: 32, color: Colors.black),
              title: Text(
                category['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutsListScreen(
                      categoryName: category['name'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
