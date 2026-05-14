import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../data/services/export_service.dart';

// ─── Colores y diseño ────────────────────────────────────────────────────────
const Color _primary      = Color(0xFF5B5FEF);
const Color _primaryLight = Color(0xFFEEF0FF);
const Color _bgColor      = Color(0xFFF8F9FF);
const Color _cardColor    = Colors.white;
const Color _textDark     = Color(0xFF1E293B);
const Color _textGray     = Color(0xFF64748B);
const Color _borderColor  = Color(0xFFE2E8F0);
const Color _green        = Color(0xFF22C55E);
const Color _greenLight   = Color(0xFFDCFCE7);
const Color _orange       = Color(0xFFF97316);
const Color _orangeLight  = Color(0xFFFFEDD5);
const Color _red          = Color(0xFFEF4444);
const Color _redLight     = Color(0xFFFEE2E2);
const Color _purple       = Color(0xFF8B5CF6);
const Color _purpleLight  = Color(0xFFF3E8FF);

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

class EntregasTareaScreen extends StatefulWidget {
  final int tareaId;
  final String tituloTarea;

  const EntregasTareaScreen({
    super.key,
    required this.tareaId,
    required this.tituloTarea,
  });

  @override
  State<EntregasTareaScreen> createState() => _EntregasTareaScreenState();
}

class _EntregasTareaScreenState extends State<EntregasTareaScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();
  final exportService = ExportService();

  List entregas = [];
  bool cargando = true;
  int totalAlumnos = 0;
  int totalEntregadas = 0;
  int totalPendientes = 0;

  // Búsqueda y filtros
  final buscarController = TextEditingController();
  String textoBusqueda = "";
  String? fechaFiltro;        // filtro único (backend)
  String? fechaInicio;        // rango (solo interfaz)
  String? fechaFin;
  String filtroEstado = 'Todos';

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
    cargarEntregas();
  }

  @override
  void dispose() {
    buscarController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> cargarEntregas({String? fecha}) async {
    setState(() => cargando = true);
    try {
      final res = await auth.obtenerReporteTarea(widget.tareaId, fecha: fecha);
      setState(() {
        totalAlumnos = res['total_alumnos'];
        totalEntregadas = res['total_entregadas'];
        totalPendientes = res['total_pendientes'];
        entregas = res['reporte'];
        fechaFiltro = fecha;
        cargando = false;
      });
      _fadeController.reset();
      _fadeController.forward();
    } catch (e) {
      print("Error cargando reporte: $e");
      setState(() => cargando = false);
    }
  }

  Future<void> seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (fecha == null) return;
    final fechaFormato =
        "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    await cargarEntregas(fecha: fechaFormato);
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
      fechaInicio =
          "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
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
      fechaFin =
          "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
    });
  }

  void limpiarFiltros() {
    setState(() {
      fechaInicio = null;
      fechaFin = null;
      filtroEstado = 'Todos';
      textoBusqueda = '';
      buscarController.clear();
    });
  }

  Future<void> exportarExcel() async {
    try {
      await exportService.exportarEntregasAvanzado(
        widget.tareaId,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: filtroEstado,
        busqueda: textoBusqueda,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte exportado correctamente")),
      );
    } catch (e) {
      print("Error exportando entregas: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo exportar el reporte")),
      );
    }
  }

  Color colorEstado(String estado) {
    return estado == 'entregado' ? _green : _orange;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    const colors = [_primary, _green, _orange, _purple, Colors.red, Colors.teal];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    // Aplicar filtros: búsqueda + estado
    final entregasFiltradas = entregas.where((item) {
      final nombre = item['nombre'].toString().toLowerCase();
      final correo = item['correo'].toString().toLowerCase();
      final busqueda = textoBusqueda.toLowerCase();
      final matchesBusqueda = nombre.contains(busqueda) || correo.contains(busqueda);
      if (filtroEstado != 'Todos') {
        final estadoItem = (item['estado'] ?? '').toString().toLowerCase();
        final filtro = filtroEstado.toLowerCase();
        return matchesBusqueda && estadoItem == filtro;
      }
      return matchesBusqueda;
    }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text("Reporte de entregas", style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _headerGradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: seleccionarFecha,
            tooltip: 'Filtrar por fecha',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: exportarExcel,
            tooltip: 'Exportar Excel',
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: () => cargarEntregas(),
              color: _primary,
              child: Column(
                children: [
                  // Tarjeta de resumen
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              widget.tituloTarea,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statChip("Alumnos", totalAlumnos, Icons.people, _primaryLight, _primary),
                                _statChip("Entregadas", totalEntregadas, Icons.check_circle, _greenLight, _green),
                                _statChip("Pendientes", totalPendientes, Icons.pending, _orangeLight, _orange),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Filtros
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Filtros de rango de fechas (solo interfaz)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: seleccionarFechaInicio,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text(
                                  fechaInicio == null
                                      ? 'Fecha inicio'
                                      : 'Inicio: $fechaInicio',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: seleccionarFechaFin,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text(
                                  fechaFin == null
                                      ? 'Fecha fin'
                                      : 'Fin: $fechaFin',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Filtro de estado y botones
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: filtroEstado,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(30)),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                                  DropdownMenuItem(value: 'entregado', child: Text('Entregadas')),
                                  DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
                                ],
                                onChanged: (v) => setState(() => filtroEstado = v ?? 'Todos'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: limpiarFiltros,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Limpiar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: exportarExcel,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Excel'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Campo de búsqueda
                        TextField(
                          controller: buscarController,
                          decoration: InputDecoration(
                            hintText: "Buscar alumno",
                            prefixIcon: const Icon(Icons.search, color: _textGray),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: _cardColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          ),
                          onChanged: (value) => setState(() => textoBusqueda = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lista de entregas
                  Expanded(
                    child: entregasFiltradas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 48, color: _textGray),
                                const SizedBox(height: 12),
                                Text(
                                  textoBusqueda.isEmpty
                                      ? "No hay alumnos en esta tarea"
                                      : "No hay coincidencias",
                                  style: const TextStyle(color: _textGray),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: entregasFiltradas.length,
                            itemBuilder: (context, index) {
                              final item = entregasFiltradas[index];
                              final nombre = item['nombre'];
                              final correo = item['correo'];
                              final fechaEntrega = item['fecha_entrega'] ?? 'Sin fecha';
                              final estado = item['estado'] ?? 'pendiente';
                              final esEntregado = estado == 'entregado';

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
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _avatarColor(nombre).withOpacity(0.15),
                                      foregroundColor: _avatarColor(nombre),
                                      child: Text(_initials(nombre), style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                    title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(correo, style: const TextStyle(fontSize: 12, color: _textGray)),
                                        if (esEntregado)
                                          Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 12, color: _textGray),
                                              const SizedBox(width: 4),
                                              Text("Entrega: $fechaEntrega", style: const TextStyle(fontSize: 12, color: _textGray)),
                                            ],
                                          ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: esEntregado ? _greenLight : _orangeLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        esEntregado ? "Entregado" : "Pendiente",
                                        style: TextStyle(
                                          color: esEntregado ? _green : _orange,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statChip(String label, int value, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text("$label: $value", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}