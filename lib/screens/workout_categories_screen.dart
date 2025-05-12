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
    log('Fetching categories from $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body);
          isLoading = false;
          hasError = false;
        });
        log('Categories loaded: ${categories.length}');
      } else {
        log('Failed to load categories: ${response.statusCode}', error: response.body);
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      log('Exception during fetch', error: e);
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Categories'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3984ad)));
          }

          if (hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text('Could not load categories.',
                      style: Theme.of(context).textTheme.bodyLarge),
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
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: List.generate(categories.length, (index) {
                final category = categories[index];
                final width = isTablet ? (constraints.maxWidth - 52) / 2 : constraints.maxWidth;

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
                      log('Opening category: ${category['name']}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutsListScreen(
                            categoryName: category['name'],
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: width,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.fitness_center,
                                  size: 36),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  category['name'],
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
