import 'package:flutter/material.dart';
import 'package:nuqta_engine/nuqta_engine.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    String version;
    try {
      version = NuqtaEngine().version;
    } catch (e) {
      version = 'engine unavailable: $e';
    }
    return MaterialApp(
      title: 'Arabic OCR',
      home: Scaffold(body: Center(child: Text(version))),
    );
  }
}
