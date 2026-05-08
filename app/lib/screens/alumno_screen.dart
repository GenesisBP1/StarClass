import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';
import 'tareas_screen.dart';
import 'qr_asistencia_screen.dart';
import 'scanner_screen.dart';

class AlumnoScreen extends StatefulWidget {
  const AlumnoScreen({super.key});

  @override
  State<AlumnoScreen> createState() => _AlumnoScreenState();
}

class _AlumnoScreenState extends State<AlumnoScreen> {
  final auth = AuthService();
  final codigoController = TextEditingController();

  List clases = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarClases();
  }

  Future<void> cargarClases() async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');

    if (alumnoId == null) {
      setState(() {
        cargando = false;
      });
      return;
    }

    try {
      final res = await auth.obtenerClasesAlumno(alumnoId);

      setState(() {
        clases = res['clases'];
        cargando = false;
      });
    } catch (e) {
      print("Error al cargar clases: $e");

      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> unirseClase() async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');

    if (alumnoId == null) return;

    try {
      await auth.unirseClase({
        "codigo_clase": codigoController.text.trim(),
        "alumno_id": alumnoId,
      });

      codigoController.clear();

      await cargarClases();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Te uniste a la clase")),
      );
    } catch (e) {
      print("Error al unirse: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo unir a la clase")),
      );
    }
  }

  void mostrarFormularioUnirse() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Unirse a clase"),
          content: TextField(
            controller: codigoController,
            decoration: const InputDecoration(
              labelText: "Código de clase",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                codigoController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await unirseClase();
              },
              child: const Text("Unirse"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Alumno"),
      ),
      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : clases.isEmpty
              ? const Center(
                  child: Text("No estás inscrito en ninguna clase"),
                )
              : ListView.builder(
                  itemCount: clases.length,
                  itemBuilder: (context, index) {
                    final clase = clases[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                        child: ListTile(
                        title: Text(clase['nombre']),
                        subtitle: Text(
                          clase['descripcion'] ?? 'Sin descripción',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.qr_code),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QrAsistenciaScreen(
                                  claseId: clase['id'],
                                  nombreClase: clase['nombre'],
                                ),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TareasScreen(
                                claseId: clase['id'],
                                nombreClase: clase['nombre'],
                                esMaestro: false,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "scannerAlumno",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ScannerScreen(),
                ),
              );
            },
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "unirseClase",
            onPressed: mostrarFormularioUnirse,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}