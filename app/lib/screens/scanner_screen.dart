import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final auth = AuthService();

  bool procesando = false;

  Future<void> procesarQr(String rawValue) async {
    if (procesando) return;
  
    setState(() {
      procesando = true;
    });
  
    try {
      final prefs = await SharedPreferences.getInstance();
      final alumnoId = prefs.getInt('id');
  
      if (alumnoId == null) {
        throw Exception("Alumno no encontrado");
      }
  
      final res = await auth.validarQr({
        "codigo": rawValue,
      });
  
      final qr = res['qr'];
  
      if (qr['tipo_uso'] == 'asistencia') {
        await auth.registrarAsistencia({
          "clase_id": qr['referencia_id'],
          "alumno_id": alumnoId,
        });
      } else {
        throw Exception("QR no válido para asistencia");
      }
  
      if (!mounted) return;
  
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Asistencia registrada correctamente"),
        ),
      );
  
      Navigator.pop(context);
  
    } catch (e) {
      print("Error escaneando QR: $e");
  
      if (!mounted) return;
  
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("QR inválido, expirado o ya usado"),
        ),
      );
  
      setState(() {
        procesando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escanear QR"),
      ),
      body: Stack(
        children: [
          MobileScanner(
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
          if (procesando)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}