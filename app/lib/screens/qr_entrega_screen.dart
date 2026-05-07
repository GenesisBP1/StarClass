import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrEntregaScreen extends StatefulWidget {
  final int tareaId;
  final String tituloTarea;

  const QrEntregaScreen({
    super.key,
    required this.tareaId,
    required this.tituloTarea,
  });

  @override
  State<QrEntregaScreen> createState() => _QrEntregaScreenState();
}

class _QrEntregaScreenState extends State<QrEntregaScreen> {
  String? qrData;

  @override
  void initState() {
    super.initState();
    generarQr();
  }

  Future<void> generarQr() async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');

    if (alumnoId == null) return;

    final data = {
      "tipo": "entrega_tarea",
      "tarea_id": widget.tareaId,
      "alumno_id": alumnoId,
      "fecha": DateTime.now().toIso8601String(),
    };

    setState(() {
      qrData = jsonEncode(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR de entrega"),
      ),
      body: Center(
        child: qrData == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.tituloTarea,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: qrData!,
                    size: 250,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Muestra este QR al maestro para registrar la entrega.",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}