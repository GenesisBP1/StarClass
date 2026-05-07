import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';
import 'tareas_screen.dart';
import 'scanner_screen.dart';
import 'asistencias_screen.dart';

class MaestroScreen extends StatefulWidget {
  const MaestroScreen({super.key});

  @override
  State<MaestroScreen> createState() => _MaestroScreenState();
}

class _MaestroScreenState extends State<MaestroScreen> {
  final auth = AuthService();
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();

  List clases = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarClases();
  }

  Future<void> cargarClases() async {
    final prefs = await SharedPreferences.getInstance();
    final maestroId = prefs.getInt('id');

    if (maestroId == null) {
      setState(() {
        cargando = false;
      });
      return;
    }

    try {
      final res = await auth.obtenerClasesMaestro(maestroId);

      setState(() {
        clases = res['clases'];
        cargando = false;
      });
    } catch (e) {
      print("Error al cargar clases del maestro: $e");
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> crearClase() async {
    final prefs = await SharedPreferences.getInstance();
    final maestroId = prefs.getInt('id');

    if (maestroId == null) return;

    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre de la clase es obligatorio")),
      );
      return;
    }

    try {
      await auth.crearClase({
        "nombre": nombreController.text.trim(),
        "descripcion": descripcionController.text.trim(),
        "maestro_id": maestroId,
      });

      nombreController.clear();
      descripcionController.clear();

      await cargarClases();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Clase creada correctamente")),
      );
    } catch (e) {
      print("Error al crear clase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo crear la clase")),
      );
    }
  }

  void mostrarFormularioClase() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Crear clase"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre de la clase",
                ),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: "Descripción",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                nombreController.clear();
                descripcionController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await crearClase();
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel Maestro"),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : clases.isEmpty
              ? const Center(child: Text("No tienes clases creadas"))
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
                          icon: const Icon(Icons.event_available),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AsistenciasScreen(
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
                                esMaestro: true,
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
            heroTag: "scanner",
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
            heroTag: "crearClase",
            onPressed: mostrarFormularioClase,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}