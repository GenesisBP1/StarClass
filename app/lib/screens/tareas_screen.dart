import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_entrega_screen.dart';
import 'qr_tarea_maestro_screen.dart';

// ─── Colores y diseño (coherentes con el resto de la app) ────────────────────
const Color _primary      = Color(0xFF5B5FEF);
const Color _primaryLight = Color(0xFFEEF0FF);
const Color _bgColor      = Color(0xFFF8F9FF);
const Color _cardColor    = Colors.white;
const Color _textDark     = Color(0xFF1E293B);
const Color _textGray     = Color(0xFF64748B);
const Color _borderColor  = Color(0xFFE2E8F0);
const Color _green        = Color(0xFF22C55E);
const Color _greenLight   = Color(0xFFDCFCE7);
const Color _red          = Color(0xFFEF4444);
const Color _redLight     = Color(0xFFFEE2E2);
const Color _orange       = Color(0xFFF97316);
const Color _orangeLight  = Color(0xFFFFEDD5);
const Color _purple       = Color(0xFF8B5CF6);
const Color _purpleLight  = Color(0xFFF3E8FF);

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

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

class _TareasScreenState extends State<TareasScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();

  // Controladores para crear tarea
  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final fechaController = TextEditingController();

  // Controladores para editar tarea
  final editTituloController = TextEditingController();
  final editDescripcionController = TextEditingController();
  final editFechaController = TextEditingController();

  List tareas = [];
  bool cargando = true;

  // Búsqueda
  final TextEditingController _buscarController = TextEditingController();
  String _textoBusqueda = "";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    cargarTareas();
  }

  Future<void> cargarTareas() async {
    try {
      final res = await auth.obtenerTareasPorClase(widget.claseId);
      setState(() {
        tareas = res['tareas'];
        cargando = false;
      });
      _fadeController.reset();
      _fadeController.forward();
    } catch (e) {
      print("Error al cargar tareas: $e");
      setState(() => cargando = false);
    }
  }

  // Crear tarea con fecha desde DatePicker
  Future<void> crearTarea() async {
    if (tituloController.text.trim().isEmpty) {
      _mostrarMensaje("El título es obligatorio");
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
      _mostrarMensaje("Tarea creada correctamente");
    } catch (e) {
      print("Error al crear tarea: $e");
      _mostrarMensaje("No se pudo crear la tarea");
    }
  }

  // Editar tarea
  Future<void> editarTarea(Map<String, dynamic> tarea) async {
    editTituloController.text = tarea['titulo'] ?? '';
    editDescripcionController.text = tarea['descripcion'] ?? '';
    editFechaController.text = tarea['fecha_entrega'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return _buildTaskDialog(
          title: "Editar tarea",
          tituloCtrl: editTituloController,
          descripcionCtrl: editDescripcionController,
          fechaCtrl: editFechaController,
          onSave: () async {
            try {
              await auth.actualizarTarea(tarea['id'], {
                "titulo": editTituloController.text.trim(),
                "descripcion": editDescripcionController.text.trim(),
                "fecha_entrega": editFechaController.text.trim().isEmpty
                    ? null
                    : editFechaController.text.trim(),
              });
              await cargarTareas();
              _mostrarMensaje("Tarea actualizada");
            } catch (e) {
              _mostrarMensaje("Error al actualizar");
            }
          },
        );
      },
    );
  }

  // Eliminar tarea
  Future<void> confirmarEliminar(int tareaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar tarea"),
        content: const Text("¿Estás seguro de que quieres eliminar esta tarea? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await auth.eliminarTarea(tareaId);
      await cargarTareas();
      _mostrarMensaje("Tarea eliminada");
    } catch (e) {
      _mostrarMensaje("Error al eliminar la tarea");
    }
  }

  // Entregar tarea (estudiante)
  Future<void> entregarTarea(int tareaId) async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');
    if (alumnoId == null) return;
    try {
      await auth.entregarTarea({
        "tarea_id": tareaId,
        "alumno_id": alumnoId,
      });
      _mostrarMensaje("Tarea entregada correctamente");
    } catch (e) {
      print("Error al entregar tarea: $e");
      _mostrarMensaje("La tarea ya fue entregada o hubo un error");
    }
  }

  // Ver entregas (profesor)
  Future<void> verEntregas(int tareaId) async {
    try {
      final res = await auth.obtenerEntregasPorTarea(tareaId);
      final entregas = res['entregas'];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
        ),
      );
    } catch (e) {
      print("Error al ver entregas: $e");
      _mostrarMensaje("No se pudieron cargar las entregas");
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Diálogo de creación/edición con DatePicker
  Future<void> _mostrarFormularioTarea() async {
    // Limpiar controladores para creación
    tituloController.clear();
    descripcionController.clear();
    fechaController.clear();

    await showDialog(
      context: context,
      builder: (context) => _buildTaskDialog(
        title: "Crear tarea",
        tituloCtrl: tituloController,
        descripcionCtrl: descripcionController,
        fechaCtrl: fechaController,
        onSave: crearTarea,
      ),
    );
  }

  Widget _buildTaskDialog({
    required String title,
    required TextEditingController tituloCtrl,
    required TextEditingController descripcionCtrl,
    required TextEditingController fechaCtrl,
    required VoidCallback onSave,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Campo título
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(
                labelText: "Título",
                hintText: "Ej. Tarea de matemáticas",
                prefixIcon: Icon(Icons.title, color: _primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Campo descripción
            TextField(
              controller: descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Descripción",
                hintText: "Detalles de la tarea...",
                prefixIcon: Icon(Icons.description, color: _primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Campo fecha con selector integrado
            GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  final formatted = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                  fechaCtrl.text = formatted;
                }
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: fechaCtrl,
                  decoration: const InputDecoration(
                    labelText: "Fecha de entrega",
                    hintText: "Selecciona una fecha",
                    prefixIcon: Icon(Icons.calendar_today, color: _primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textGray,
                      side: const BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSave();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      title == "Crear tarea" ? "Crear" : "Guardar",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String text) {
    if (text.isEmpty) return "?";
    return text[0].toUpperCase();
  }

  @override
  void dispose() {
    tituloController.dispose();
    descripcionController.dispose();
    fechaController.dispose();
    editTituloController.dispose();
    editDescripcionController.dispose();
    editFechaController.dispose();
    _buscarController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar tareas
    final tareasFiltradas = _textoBusqueda.isEmpty
        ? tareas
        : tareas.where((tarea) {
            final titulo = tarea['titulo'].toString().toLowerCase();
            final descripcion = tarea['descripcion']?.toString().toLowerCase() ?? '';
            final busqueda = _textoBusqueda.toLowerCase();
            return titulo.contains(busqueda) || descripcion.contains(busqueda);
          }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(widget.nombreClase, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _headerGradient)),
        actions: [
          if (widget.esMaestro)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _mostrarFormularioTarea,
              tooltip: 'Crear tarea',
            ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: cargarTareas,
              color: _primary,
              child: Column(
                children: [
                  // Campo de búsqueda
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _buscarController,
                      decoration: InputDecoration(
                        hintText: "Buscar tarea",
                        prefixIcon: const Icon(Icons.search, color: _textGray),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _cardColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (value) => setState(() => _textoBusqueda = value),
                    ),
                  ),
                  Expanded(
                    child: tareasFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assignment_late, size: 48, color: _textGray),
                                const SizedBox(height: 12),
                                Text(
                                  _textoBusqueda.isEmpty
                                      ? "No hay tareas en esta clase"
                                      : "No hay tareas que coincidan",
                                  style: const TextStyle(color: _textGray),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: tareasFiltradas.length,
                            itemBuilder: (context, index) {
                              final tarea = tareasFiltradas[index];
                              final titulo = tarea['titulo'];
                              final descripcion = tarea['descripcion'] ?? 'Sin descripción';
                              final fechaEntrega = tarea['fecha_entrega'] ?? 'Sin fecha';
                              final esMaestro = widget.esMaestro;

                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: _cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: _primaryLight,
                                          foregroundColor: _primary,
                                          child: Text(_initials(titulo), style: const TextStyle(fontWeight: FontWeight.w700)),
                                        ),
                                        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(descripcion, maxLines: 2, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, size: 12, color: _textGray),
                                                const SizedBox(width: 4),
                                                Text("Entrega: $fechaEntrega", style: const TextStyle(fontSize: 12, color: _textGray)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: esMaestro
                                            ? PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, color: _textGray),
                                                onSelected: (value) async {
                                                  if (value == 'ver_entregas') {
                                                    await verEntregas(tarea['id']);
                                                  } else if (value == 'generar_qr') {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => QrTareaMaestroScreen(
                                                          tareaId: tarea['id'],
                                                          tituloTarea: titulo,
                                                        ),
                                                      ),
                                                    );
                                                  } else if (value == 'editar') {
                                                    await editarTarea(tarea);
                                                  } else if (value == 'eliminar') {
                                                    await confirmarEliminar(tarea['id']);
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'ver_entregas',
                                                    child: Row(children: [
                                                      Icon(Icons.visibility, size: 20),
                                                      SizedBox(width: 8),
                                                      Text("Ver entregas"),
                                                    ]),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'generar_qr',
                                                    child: Row(children: [
                                                      Icon(Icons.qr_code, size: 20),
                                                      SizedBox(width: 8),
                                                      Text("Generar QR"),
                                                    ]),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'editar',
                                                    child: Row(children: [
                                                      Icon(Icons.edit, size: 20),
                                                      SizedBox(width: 8),
                                                      Text("Editar"),
                                                    ]),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'eliminar',
                                                    child: Row(children: [
                                                      Icon(Icons.delete, size: 20),
                                                      SizedBox(width: 8),
                                                      Text("Eliminar"),
                                                    ]),
                                                  ),
                                                ],
                                              )
                                            : ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => QrEntregaScreen(
                                                        tareaId: tarea['id'],
                                                        tituloTarea: titulo,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: _primary,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30),
                                                  ),
                                                ),
                                                child: const Text("Entregar"),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: widget.esMaestro
          ? FloatingActionButton(
              onPressed: _mostrarFormularioTarea,
              backgroundColor: _primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}