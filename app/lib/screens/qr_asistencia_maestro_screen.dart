import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/services/auth_service.dart';

class QrAsistenciaMaestroScreen extends StatefulWidget {
  final int claseId;
  final String nombreClase;

  const QrAsistenciaMaestroScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
  });

  @override
  State<QrAsistenciaMaestroScreen> createState() =>
      _QrAsistenciaMaestroScreenState();
}

class _QrAsistenciaMaestroScreenState
    extends State<QrAsistenciaMaestroScreen> {
  final auth = AuthService();

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
    try {
      final res = await auth.generarQr({
        "alumno_id": 1,
        "tipo_uso": "asistencia",
        "referencia_id": widget.claseId,
      });

      setState(() {
        qrData = res['codigo'];
      });
    } catch (e) {
      print("Error generando QR de asistencia del maestro: $e");
    }
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
                    "Los alumnos deben escanear este QR para registrar asistencia.",
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