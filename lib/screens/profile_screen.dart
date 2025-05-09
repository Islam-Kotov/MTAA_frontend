import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'all_screens.dart';

Future<Uint8List> showPrivate(String photo_url) async {
  final url = Uri.parse(photo_url);

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  return response.bodyBytes;
}

Future<Map<String, dynamic>?> getProfile() async {
  final url = Uri.parse('http://192.168.1.36:8000/api/profile');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    print('Failed to load profile: ${response.body}');
    return null;
  }
}

Future<bool> logout() async {
  final url = Uri.parse('http://192.168.1.36:8000/api/logout');

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
  Map<String, dynamic>? profileData;
  Uint8List? profileImageBytes;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final data = await getProfile();
    setState(() {
      profileData = data;
      isLoading = false;
    });
    if (data!['photo_url'] != null) {
      final avatar = await showPrivate(data['photo_url']);
      setState(() {
        profileImageBytes = avatar;
      });
    }
    
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileData == null) {
      return Scaffold(
        body: Center(child: Text('Failed to load profile.')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Color.fromRGBO(200, 230, 255, 1), // Light blue background
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: profileImageBytes != null
                    ? MemoryImage(profileImageBytes!)
                    : null,
                  child: profileImageBytes == null
                    ? Icon(Icons.person, size: 40)
                    : null,
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileData!['name'] ?? '',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    SizedBox(height: 4),
                    Text(
                      profileData!['email'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54
                      )
                    ),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(57, 132, 173, 1),
                      fixedSize: Size(286, 68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))
                      )
                    ),
                    onPressed: () async {
                    },
                    child: const Text(
                      'My profile',
                      style: TextStyle(
                        color:Color.fromRGBO(0, 0, 0, 1),
                        fontSize: 24
                      ),
                    )
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(57, 132, 173, 1),
                      fixedSize: Size(286, 68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))
                      )
                    ),
                    onPressed: () async {
                    },
                    child: const Text(
                      'Settings',
                      style: TextStyle(
                        color:Color.fromRGBO(0, 0, 0, 1),
                        fontSize: 24
                      ),
                    )
                  ),
                  ElevatedButton(
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
                ],
              ),
            )
          ),
        ],
      )
    );
  }
}