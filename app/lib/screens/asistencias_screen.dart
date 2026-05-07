import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';

class AsistenciasScreen extends StatefulWidget {
  final int claseId;
  final String nombreClase;

  const AsistenciasScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
  });

  @override
  State<AsistenciasScreen> createState() => _AsistenciasScreenState();
}

class _AsistenciasScreenState extends State<AsistenciasScreen> {
  final auth = AuthService();

  List asistencias = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarAsistencias();
  }

  Future<void> cargarAsistencias() async {
    try {
      final res = await auth.obtenerAsistenciasPorClase(widget.claseId);

      setState(() {
        asistencias = res['asistencias'];
        cargando = false;
      });
    } catch (e) {
      print("Error al cargar asistencias: $e");

      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Asistencias - ${widget.nombreClase}"),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : asistencias.isEmpty
              ? const Center(child: Text("No hay asistencias registradas"))
              : ListView.builder(
                  itemCount: asistencias.length,
                  itemBuilder: (context, index) {
                    final asistencia = asistencias[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(asistencia['nombre']),
                        subtitle: Text(
                          "${asistencia['correo']}\nFecha: ${asistencia['fecha']}  Hora: ${asistencia['hora']}",
                        ),
                        trailing: Text(asistencia['estado']),
                      ),
                    );
                  },
                ),
    );
  }
}