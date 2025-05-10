import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import 'workouts_list_screen.dart';

class WorkoutCategoriesScreen extends StatefulWidget {
  const WorkoutCategoriesScreen({super.key});

  @override
  State<WorkoutCategoriesScreen> createState() => _WorkoutCategoriesScreenState();
}

class _WorkoutCategoriesScreenState extends State<WorkoutCategoriesScreen> {
  List categories = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    final uri = Uri.parse('http://192.168.1.36:8000/api/categories');
    log('📡 Fetching categories from $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body);
          isLoading = false;
          hasError = false;
        });
        log('✅ Categories loaded: ${categories.length}');
      } else {
        log('❌ Failed to load categories: ${response.statusCode}', error: response.body);
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      log('❗ Exception during fetch', error: e);
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
      appBar: AppBar(
        title: const Text('Workout Categories'),
        backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
        elevation: 2,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF3984ad)),
      )
          : hasError
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Could not load categories.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () {
                setState(() {
                  isLoading = true;
                  hasError = false;
                });
                fetchCategories();
              },
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + index * 100),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            ),
            child: GestureDetector(
              onTap: () {
                log('➡️ Opening category: ${category['name']}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutsListScreen(
                      categoryName: category['name'],
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, size: 36, color: Colors.blueAccent),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          category['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
