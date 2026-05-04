import 'package:flutter/material.dart';

class AlumnoScreen extends StatelessWidget {
  const AlumnoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Alumno")),
      body: const Center(child: Text("Bienvenido Alumno")),
    );
  }
}