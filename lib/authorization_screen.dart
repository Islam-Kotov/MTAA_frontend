import 'package:flutter/material.dart';

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreen();
}

class _AuthorizationScreen extends State<AuthorizationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                        FilledButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(57, 132, 173, 1),
                            fixedSize: Size(286, 68),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10))
                            )
                          ),
                          onPressed: () {},
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
                                onPressed: () {},
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