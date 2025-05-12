import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreen();
}

class _TestScreen extends State<TestScreen> { 
  late final WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(
      Uri.parse('ws://147.175.163.45:8080/app/cfdjqmnqx0vggflribbd?protocol=7&client=js&version=1.0&format=json'),
    );
    channel.sink.add(jsonEncode(
      {
        'event': 'pusher:subscribe',
        'data': {
          'channel': 'test'
        }
      }
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder(
          stream: channel.stream,
          builder: (context, snapshot) {
            return Text(snapshot.hasData ? '${snapshot.data}' : '');
          },
        ),
      )
      
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }
}