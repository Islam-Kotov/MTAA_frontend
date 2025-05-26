import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'all_screens.dart';

Future<bool> createUser(String name, String email, String password, String passwordConfirmation) async {
  final url = Uri.parse('http://147.175.162.111:8000/api/auth/register');

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

    print('User created successfully');
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

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(207, 228, 242, 1),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 32),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 210,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                DefaultTextStyle(
                                  style: TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 1),
                                    fontSize: 40,
                                    fontStyle: FontStyle.normal,
                                  ),
                                  child: Text('FitLife'),
                                ),
                                Image(image: AssetImage('assets/images/dumbell_icon.png')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Column(
                            children: [
                              _buildInputField(_nameController, 'Enter name...'),
                              const SizedBox(height: 16),
                              _buildInputField(_emailController, 'Enter e-mail...', inputType: TextInputType.emailAddress),
                              const SizedBox(height: 16),
                              _buildPasswordField(_passwordController, 'Enter password...', _obscurePassword, () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              }),
                              const SizedBox(height: 16),
                              _buildPasswordField(_passwordConfirmationController, 'Confirm password...', _obscureConfirmPassword, () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              }),
                              const SizedBox(height: 32),
                              FilledButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(57, 132, 173, 1),
                                  fixedSize: const Size(286, 68),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10)),
                                  ),
                                ),
                                onPressed: () async {
                                  final success = await createUser(
                                    _nameController.text,
                                    _emailController.text,
                                    _passwordController.text,
                                    _passwordConfirmationController.text,
                                  );

                                  if (!mounted) return;

                                  if (success) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const FillProfileInfoScreen()),
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
                                    color: Color.fromRGBO(0, 0, 0, 1),
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              RichText(
                                text: TextSpan(
                                  text: 'I already have an account.',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 18.0,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const AuthorizationScreen()),
                                      );
                                    },
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, {TextInputType inputType = TextInputType.text}) {
    return SizedBox(
      height: 68,
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 1),
          hintText: hint,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool obscureText, VoidCallback toggle) {
    return SizedBox(
      height: 68,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 1),
          hintText: hint,
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: toggle,
          ),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
