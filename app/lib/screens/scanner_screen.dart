import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/services/auth_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final auth = AuthService();

  bool procesando = false;
  String mensaje = "";


  Future<void> procesarQr(String rawValue) async {
    if (procesando) return;

    procesando = true;
    try {
      final data = jsonDecode(rawValue);
      final fechaQr = DateTime.parse(data['fecha']);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fechaQr).inMinutes;
      
      if (diferencia > 5) {
        throw Exception("QR expirado");
      }


      if (data['tipo'] == 'entrega_tarea') {
        await auth.entregarTarea({
          "tarea_id": data['tarea_id'],
          "alumno_id": data['alumno_id'],
        });

        mensaje = "Entrega registrada correctamente";
      } else if (data['tipo'] == 'asistencia') {
        await auth.registrarAsistencia({
          "clase_id": data['clase_id'],
          "alumno_id": data['alumno_id'],
        });

        mensaje = "Asistencia registrada correctamente";
      } else {
        throw Exception("QR inválido");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Entrega registrada correctamente"),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      print("Error escaneando QR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QR inválido o entrega duplicada"),
        ),
      );
    }

    procesando = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear QR"),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;

          for (final barcode in barcodes) {
            final raw = barcode.rawValue;

            if (raw != null) {
              procesarQr(raw);
              break;
            }
          }
        },
      ),
    );
  }
}