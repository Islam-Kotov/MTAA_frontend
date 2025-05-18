import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  return response.statusCode == 200;
}

enum Gender { male, female }

class FillProfileInfoScreen extends StatefulWidget {
  const FillProfileInfoScreen({super.key});

  @override
  State<FillProfileInfoScreen> createState() => _FillProfileInfoScreen();
}

class _FillProfileInfoScreen extends State<FillProfileInfoScreen> {
  Gender? _gender;
  final birthdateController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  void setGender(Gender? value) {
    setState(() {
      _gender = value;
    });
  }

  Widget buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete profile info'),
          backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
        ),
        backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : double.infinity,
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                    buildInputField('Weight', weightController),
                    buildInputField('Height', heightController),
                    buildInputField('Birthdate', birthdateController),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final weight = weightController.text;
                        final height = heightController.text;
                        final birthdate = birthdateController.text;
                        String? gender;

                        switch (_gender) {
                          case Gender.male:
                            gender = 'male';
                            break;
                          case Gender.female:
                            gender = 'female';
                            break;
                          default:
                            gender = null;
                        }

                        final success = await saveProfileWithGender(weight, height, birthdate, gender);

                        if (!mounted) return;

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
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
