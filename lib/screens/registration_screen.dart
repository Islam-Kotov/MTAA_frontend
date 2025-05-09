import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'all_screens.dart';

Future<bool> createUser(String name, String email, String password, String passwordConfirmation) async {
  final url = Uri.parse('http://192.168.1.36:8000/api/auth/register');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final token = data['token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);

    print('User created successfuly');
    return true;
  } else {
    print('Registration failed: ${response.body}');
    return false;
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreen();
}

class _RegistrationScreen extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Color.fromRGBO(207, 228, 242, 1),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 30, horizontal: 64),
              child: Column(
                children: [
                  SizedBox(
                    height: 210,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const DefaultTextStyle(
                          style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 1),
                            fontSize: 40,
                            fontStyle: FontStyle.normal
                          ),
                          child: Text('FitLife')
                        ),
                        Image(
                          image: AssetImage(
                            'assets/images/dumbell_icon.png'
                          )
                        ),
                      ]
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 510,
                    width: 286,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 68,
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 22),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              filled: true,
                              fillColor: Color.fromRGBO(255, 255, 255, 1),
                              hintText: 'Enter name...',
                            ),
                            textAlign: TextAlign.center,
                          )
                        ),
                        SizedBox(
                          height: 68,
                          child: TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 22),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              filled: true,
                              fillColor: Color.fromRGBO(255, 255, 255, 1),
                              hintText: 'Enter e-mail...',
                            ),
                            textAlign: TextAlign.center,
                          )
                        ),
                        SizedBox(
                          height: 68,
                          child: TextField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 22),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              filled: true,
                              fillColor: Color.fromRGBO(255, 255, 255, 1),
                              hintText: 'Enter password...',
                            ),
                            textAlign: TextAlign.center,
                          )
                        ),
                        SizedBox(
                          height: 68,
                          child: TextField(
                            controller: _passwordConfirmationController,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 22),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              filled: true,
                              fillColor: Color.fromRGBO(255, 255, 255, 1),
                              hintText: 'Confirm password...',
                            ),
                            textAlign: TextAlign.center,
                          )
                        ),
                        SizedBox(
                          height: 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FilledButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromRGBO(57, 132, 173, 1),
                                  fixedSize: Size(286, 68),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10))
                                  )
                                ),
                                onPressed: () async {
                                  final success = await createUser(
                                    _nameController.text,
                                    _emailController.text,
                                    _passwordController.text,
                                    _passwordConfirmationController.text,
                                  );

                                  if (!mounted) return; // Prevent using context if widget is disposed

                                  if (success) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Registration failed')),
                                    );
                                  }
                                },
                                child: const Text(
                                  'Create an account',
                                  style: TextStyle(
                                    color:Color.fromRGBO(0, 0, 0, 1),
                                    fontSize: 20
                                  ),
                                )
                              ),
                              RichText(
                                text: TextSpan(
                                  text: 'I already have an account.',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 18.0,
                                    decoration: TextDecoration.underline
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const AuthorizationScreen()),
                                      );
                                    }),
                              ),
                            ]
                          )
                        )
                      ],
                    )
                  )
                ],
              ),
            )
          ),
        )
      )
    )
    ;
  }
}