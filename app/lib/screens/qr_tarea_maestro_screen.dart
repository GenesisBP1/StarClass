import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/services/auth_service.dart';

class QrTareaMaestroScreen extends StatefulWidget {
  final int tareaId;
  final String tituloTarea;

  const QrTareaMaestroScreen({
    super.key,
    required this.tareaId,
    required this.tituloTarea,
  });

  @override
  State<QrTareaMaestroScreen> createState() => _QrTareaMaestroScreenState();
}

class _QrTareaMaestroScreenState extends State<QrTareaMaestroScreen> {
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
      print("Generando QR de tarea (maestro) - tareaId: ${widget.tareaId}");
      final res = await auth.generarQr({
        "alumno_id": null,
        "tipo_uso": "tarea",
        "referencia_id": widget.tareaId,
      });

      print("RESPUESTA QR (tarea, maestro): $res");

      setState(() {
        qrData = (res != null && res['codigo'] != null) ? res['codigo'] : null;
      });
      if (res == null || res['codigo'] == null) {
        print("La respuesta no contiene 'codigo' para el QR (tarea, maestro)");
      }
    } catch (e) {
      print("Error generando QR de tarea del maestro: $e");
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
        title: const Text("QR de tarea"),
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: qrData!,
                    size: 250,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Los alumnos deben escanear este QR para marcar la tarea como entregada.",
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