import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'all_screens.dart';

Future<bool> saveProfileWithGender(String weight, String height, String birthdate, String? gender) async {
  if (gender == null) {
    print('Gender not picked');
    return false;
  }
  final url = Uri.parse('http://192.168.1.36:8000/api/profile');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('api_token');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'weight': weight,
      'height': height,
      'birthdate': birthdate,
      'gender': gender
    }),
  );

  if (response.statusCode == 200) {
    print('${response.body}');
    return true;
  } else {
    print('${response.body}');
    return false;
  }
}

enum Gender { male, female }

class FillProfileInfoScreen extends StatefulWidget {
  const FillProfileInfoScreen({super.key});

  @override
  State<FillProfileInfoScreen> createState() => _FillProfileInfoScreen();
}

class _FillProfileInfoScreen extends State<FillProfileInfoScreen> {
  Gender? _gender;

  void setGender(Gender? value) {
    setState(() {
      _gender = value;
    });
  }

  final birthdateController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete profile info'),
          backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
        ),
        backgroundColor: Color.fromRGBO(207, 228, 242, 1),
        body: Column(
          children: [
            ListTile(
              title: const Text('Male'),
              leading: Radio<Gender>(
                value: Gender.male,
                groupValue: _gender,
                onChanged: setGender,
              ),
            ),
            ListTile(
              title: const Text('Female'),
              leading: Radio<Gender>(
                value: Gender.female,
                groupValue: _gender,
                onChanged: setGender,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24.0),
              child: Column(
                spacing: 24,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: weightController,
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      border: OutlineInputBorder()
                    ),
                  ),
                  TextField(
                    controller: heightController,
                    decoration: InputDecoration(
                      labelText: 'Height',
                      border: OutlineInputBorder()
                    ),
                  ),
                  TextField(
                    controller: birthdateController,
                    decoration: InputDecoration(
                      labelText: 'Birthdate',
                      border: OutlineInputBorder()
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {

                final weight = weightController.text;
                final height = heightController.text;
                final birthdate = birthdateController.text;
                String? gender = null;

                switch (_gender) {
                  case Gender.male:
                    gender = 'male';
                    break;
                  case Gender.female:
                    gender = 'female';
                    break;
                  default:
                }

                final success = await saveProfileWithGender(weight, height, birthdate, gender);

                if (!mounted) return; // Prevent using context if widget is disposed
                
                if (success) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile info save failed')),
                  );
                }
              },
              child: Text('Confirm')
            )
          ],
        )
      )
    );
  }
}