import 'package:flutter/material.dart';
import 'speisekarte.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Was gibt's heute zu essen?",
      home: Speisekarte(),
    );
  }
}
