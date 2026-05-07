import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrAsistenciaScreen extends StatefulWidget {
  final int claseId;
  final String nombreClase;

  const QrAsistenciaScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
  });

  @override
  State<QrAsistenciaScreen> createState() => _QrAsistenciaScreenState();
}

class _QrAsistenciaScreenState extends State<QrAsistenciaScreen> {
  String? qrData;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    generarQr();

    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      generarQr();
    });
  }

  Future<void> generarQr() async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');

    if (alumnoId == null) return;

    final data = {
      "tipo": "asistencia",
      "clase_id": widget.claseId,
      "alumno_id": alumnoId,
      "fecha": DateTime.now().toIso8601String(),
    };

    setState(() {
      qrData = jsonEncode(data);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("QR de asistencia"),
      ),
      body: Center(
        child: qrData == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.nombreClase,
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
                    "Muestra este QR al maestro para registrar tu asistencia.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "El QR se actualiza cada 30 segundos.",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}