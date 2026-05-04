import 'package:flutter/material.dart';

class MaestroScreen extends StatelessWidget {
  const MaestroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Maestro")),
      body: const Center(child: Text("Bienvenido Maestro")),
    );
  }
}