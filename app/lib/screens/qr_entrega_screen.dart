import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';

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
    final auth = AuthService();

    if (alumnoId == null) return;

    try {
      final res = await auth.generarQr({
        "alumno_id": alumnoId,
        "tipo_uso": "tarea",
        "referencia_id": widget.tareaId,
      });

      setState(() {
        qrData = res['codigo'];
      });
    } catch (e) {
      print("Error generando QR de entrega: $e");
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