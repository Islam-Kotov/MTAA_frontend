import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'authorization_screen.dart';

Future<bool> logout() async {
  final url = Uri.parse('http://192.168.1.245:8000/api/logout');
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.delete(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    print('${response.body}');
    return true;
  } else {
    print('${response.body}');
    return false;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromRGBO(57, 132, 173, 1),
            fixedSize: Size(286, 68),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10))
            )
          ),
          onPressed: () async {
            final success = await logout();

            if (!mounted) return; // Prevent using context if widget is disposed

            if (success) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthorizationScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout failed')),
              );
            }

          },
          child: const Text(
            'Logout',
            style: TextStyle(
              color:Color.fromRGBO(0, 0, 0, 1),
              fontSize: 24
            ),
          )
        ),
      )
    );
  }
}