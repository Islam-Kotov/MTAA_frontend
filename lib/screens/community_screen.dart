import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'friends_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

Future<void> sayHello() async {
  final url = Uri.parse('http://192.168.1.36:8000/api/sayHello');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
}

class _CommunityScreenState extends State<CommunityScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _friendsFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _friendsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ButtonStyle _buttonStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(double.infinity, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeTransition(
                  opacity: _friendsFade,
                  child: ElevatedButton.icon(
                    style: _buttonStyle(context),
                    icon: const Icon(Icons.people_outline, size: 28),
                    label: Text(
                      'Friends',
                      style: textStyle.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FriendsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: _buttonStyle(context),
                  icon: const Icon(Icons.waving_hand_outlined),
                  label: Text('Say Hello', style: textStyle.titleMedium),
                  onPressed: () async {
                    await sayHello();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('👋 Hello sent to server')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
