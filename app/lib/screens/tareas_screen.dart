import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_entrega_screen.dart';

class TareasScreen extends StatefulWidget {
  final int claseId;
  final String nombreClase;
  final bool esMaestro;

  const TareasScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
    required this.esMaestro,
  });

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  final auth = AuthService();

  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final fechaController = TextEditingController();

  List tareas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarTareas();
  }

  Future<void> cargarTareas() async {
    try {
      final res = await auth.obtenerTareasPorClase(widget.claseId);

      setState(() {
        tareas = res['tareas'];
        cargando = false;
      });
    } catch (e) {
      print("Error al cargar tareas: $e");
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> crearTarea() async {
    if (tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El título es obligatorio")),
      );
      return;
    }

    try {
      await auth.crearTarea({
        "clase_id": widget.claseId,
        "titulo": tituloController.text.trim(),
        "descripcion": descripcionController.text.trim(),
        "fecha_entrega": fechaController.text.trim().isEmpty
            ? null
            : fechaController.text.trim(),
      });

      tituloController.clear();
      descripcionController.clear();
      fechaController.clear();

      await cargarTareas();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tarea creada correctamente")),
      );
    } catch (e) {
      print("Error al crear tarea: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo crear la tarea")),
      );
    }
  }

  Future<void> entregarTarea(int tareaId) async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');

    if (alumnoId == null) return;

    try {
      await auth.entregarTarea({
        "tarea_id": tareaId,
        "alumno_id": alumnoId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tarea entregada correctamente")),
      );
    } catch (e) {
      print("Error al entregar tarea: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La tarea ya fue entregada o hubo un error")),
      );
    }
  }

  Future<void> verEntregas(int tareaId) async {
    try {
      final res = await auth.obtenerEntregasPorTarea(tareaId);
      final entregas = res['entregas'];

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Entregas"),
            content: entregas.isEmpty
                ? const Text("Nadie ha entregado esta tarea")
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entregas.length,
                      itemBuilder: (context, index) {
                        final entrega = entregas[index];

                        return ListTile(
                          title: Text(entrega['nombre']),
                          subtitle: Text(entrega['correo']),
                          trailing: Text(entrega['fecha_revision']),
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error al ver entregas: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudieron cargar las entregas")),
      );
    }
  }

  void mostrarFormularioTarea() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Crear tarea"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloController,
                decoration: const InputDecoration(labelText: "Título"),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
              TextField(
                controller: fechaController,
                decoration: const InputDecoration(
                  labelText: "Fecha entrega",
                  hintText: "2026-05-10",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                tituloController.clear();
                descripcionController.clear();
                fechaController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await crearTarea();
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
    tituloController.dispose();
    descripcionController.dispose();
    fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreClase),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : tareas.isEmpty
              ? const Center(child: Text("No hay tareas en esta clase"))
              : ListView.builder(
                  itemCount: tareas.length,
                  itemBuilder: (context, index) {
                    final tarea = tareas[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(tarea['titulo']),
                        subtitle: Text(tarea['descripcion'] ?? 'Sin descripción'),
                        trailing: widget.esMaestro
                            ? ElevatedButton(
                                onPressed: () {
                                  verEntregas(tarea['id']);
                                },
                                child: const Text("Ver entregas"),
                              )
                            : ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QrEntregaScreen(
                                  tareaId: tarea['id'],
                                  tituloTarea: tarea['titulo'],
                                ),
                              ),
                            );
                          },
                          child: const Text("Generar QR"),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: widget.esMaestro
          ? FloatingActionButton(
              onPressed: mostrarFormularioTarea,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}