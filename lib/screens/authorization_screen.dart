import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'all_screens.dart';

Future<bool> loginUser(String email, String password) async {
  final url = Uri.parse('http://192.168.1.36:8000/api/auth/login');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final token = data['token'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);

    print('Login successful, token saved');
    return true;
  } else {
    print('Login failed: ${response.body}');
    return false;
  }
}

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreen();
}

class _AuthorizationScreen extends State<AuthorizationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

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
              margin: EdgeInsets.symmetric(vertical: 40, horizontal: 64),
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
                    height: 457,
                    width: 286,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 22),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(10))
                              ),
                              filled: true,
                              fillColor: Color.fromRGBO(255, 255, 255, 1),
                              hintText: 'Enter password...',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            textAlign: TextAlign.center,
                          )
                        ),
                        FilledButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(57, 132, 173, 1),
                            fixedSize: Size(286, 68),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            )
                          ),
                          onPressed: () async {
                            final success = await loginUser(
                              _emailController.text,
                              _passwordController.text
                            );

                            if (!mounted) return; // Prevent using context if widget is disposed

                            if (success) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Login failed')),
                              );
                            }
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color:Color.fromRGBO(0, 0, 0, 1),
                              fontSize: 24
                            ),
                          )
                        ),
                        SizedBox(
                          height: 120,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const DefaultTextStyle(
                                style: TextStyle(
                                  color: Color.fromRGBO(0, 0, 0, 1),
                                  fontSize: 18,
                                  fontStyle: FontStyle.normal
                                ),
                                child: Text("Don't have an account?")
                              ),
                              FilledButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromRGBO(57, 132, 173, 1),
                                  fixedSize: Size(286, 68),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10))
                                  )
                                ),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                                  );
                                },
                                child: const Text(
                                  'Create an account',
                                  style: TextStyle(
                                    color:Color.fromRGBO(0, 0, 0, 1),
                                    fontSize: 20
                                  ),
                                )
                              )
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