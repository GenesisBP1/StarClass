import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../data/services/export_service.dart';

class ReporteTareasScreen extends StatefulWidget {
  final int claseId;
  final String nombreClase;

  const ReporteTareasScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
  });

  @override
  State<ReporteTareasScreen> createState() => _ReporteTareasScreenState();
}

class _ReporteTareasScreenState extends State<ReporteTareasScreen> {
  final auth = AuthService();
  final exportService = ExportService();

  List tareas = [];
  bool cargando = true;

  int totalTareas = 0;
  int tareasVencidas = 0;
  int tareasProximas = 0;

  String filtroEstado = "Todos";
  String? fechaFiltro;
  // Filtros avanzados
  String? fechaInicio;
  String? fechaFin;

  // Controladores para búsqueda
  final buscarController = TextEditingController();
  String textoBusqueda = "";

  @override
  void initState() {
    super.initState();
    cargarReporte();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  Future<void> cargarReporte({String? fecha, String? estado}) async {
    setState(() {
      cargando = true;
    });

    try {
      final res = await auth.obtenerReporteTareasClase(
        widget.claseId,
        fecha: fecha,
        estado: estado,
      );

      setState(() {
        totalTareas = res['total_tareas'];
        tareasVencidas = res['tareas_vencidas'];
        tareasProximas = res['tareas_proximas'];
        tareas = res['reporte'];
        cargando = false;
      });
    } catch (e) {
      print("Error cargando reporte de tareas: $e");
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (fecha == null) return;

    final fechaFormato =
        "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";

    setState(() {
      fechaFiltro = fechaFormato;
    });

    await cargarReporte(
      fecha: fechaFiltro,
      estado: filtroEstado,
    );
  }

  Future<void> seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (fecha == null) return;

    setState(() {
      fechaInicio = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    });
  }

  Future<void> seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (fecha == null) return;

    setState(() {
      fechaFin = "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    });
  }

  Color colorEstado(String estado) {
    if (estado == 'Vencida') {
      return Colors.red;
    }
    return Colors.green;
  }

  void limpiarFiltros() {
    setState(() {
      filtroEstado = "Todos";
      fechaFiltro = null;
      textoBusqueda = "";
      buscarController.clear();
    });

    cargarReporte();
  }

  Future<void> exportarExcel() async {
    try {
      await exportService.exportarTareasAvanzado(
        widget.claseId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: filtroEstado,
        busqueda: textoBusqueda,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte exportado correctamente")),
      );
    } catch (e) {
      print("Error exportando tareas: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo exportar el reporte")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtro por búsqueda (título o descripción) y por estado
    final tareasFiltradasBusqueda = tareas.where((item) {
      final titulo = item['titulo'].toString().toLowerCase();
      final descripcion =
          (item['descripcion'] ?? '').toString().toLowerCase();
      final busqueda = textoBusqueda.toLowerCase();

      final matchesBusqueda = titulo.contains(busqueda) || descripcion.contains(busqueda);

      if (filtroEstado != 'Todos') {
        final estadoItem = (item['estado'] ?? '').toString();
        return matchesBusqueda && estadoItem == filtroEstado;
      }

      return matchesBusqueda;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Reporte tareas - ${widget.nombreClase}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: seleccionarFecha,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: limpiarFiltros,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          fechaFiltro == null
                              ? "Todas las fechas"
                              : "Fecha: $fechaFiltro",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Total tareas: $totalTareas"),
                        Text("Vencidas: $tareasVencidas"),
                        Text("Próximas: $tareasProximas"),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<String>(
                    value: filtroEstado,
                    decoration: const InputDecoration(
                      labelText: "Filtrar por estado",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Todos",
                        child: Text("Todos"),
                      ),
                      DropdownMenuItem(
                        value: "Vencida",
                        child: Text("Vencidas"),
                      ),
                      DropdownMenuItem(
                        value: "Próxima",
                        child: Text("Próximas"),
                      ),
                    ],
                    onChanged: (value) async {
                      setState(() {
                        filtroEstado = value!;
                      });

                      await cargarReporte(
                        fecha: fechaFiltro,
                        estado: filtroEstado,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Filtros visuales: fecha inicio/fin, limpiar y exportar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: seleccionarFechaInicio,
                              child: Text(fechaInicio == null
                                  ? 'Seleccionar fecha inicio'
                                  : 'Inicio: $fechaInicio'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: seleccionarFechaFin,
                              child: Text(fechaFin == null
                                  ? 'Seleccionar fecha fin'
                                  : 'Fin: $fechaFin'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: buscarController,
                              decoration: const InputDecoration(
                                labelText: "Buscar tarea",
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  textoBusqueda = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: limpiarFiltros,
                            child: const Text('Limpiar filtros'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: exportarExcel,
                            child: const Text('Exportar Excel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: tareasFiltradasBusqueda.isEmpty
                      ? const Center(
                          child: Text(
                            "No hay tareas que coincidan con la búsqueda",
                          ),
                        )
                      : ListView.builder(
                          itemCount: tareasFiltradasBusqueda.length,
                          itemBuilder: (context, index) {
                            final tarea = tareasFiltradasBusqueda[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(tarea['titulo']),
                                subtitle: Text(
                                  "${tarea['descripcion'] ?? 'Sin descripción'}\nFecha entrega: ${tarea['fecha_entrega']}",
                                ),
                                trailing: Text(
                                  tarea['estado'],
                                  style: TextStyle(
                                    color: colorEstado(tarea['estado']),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}