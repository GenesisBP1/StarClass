import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../data/services/export_service.dart';

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

class _AsistenciasScreenState extends State<AsistenciasScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();
  final exportService = ExportService();

  List reporte = [];
  bool cargando = true;

  String? fechaConsultada;
  int totalAlumnos = 0;
  int totalPresentes = 0;
  int totalFaltas = 0;

  final buscarController = TextEditingController();
  String textoBusqueda = "";

  // Filtros (solo frontend, el backend actual solo admite una fecha concreta)
  String filtroEstado = 'Todos';

  // Animación para la lista
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
    cargarAsistencias();
  }

  Future<void> cargarAsistencias({String? fecha}) async {
    setState(() {
      cargando = true;
    });

    try {
      final res = await auth.obtenerAsistenciasPorClase(
        widget.claseId,
        fecha: fecha,
      );

      setState(() {
        fechaConsultada = res['fecha_consultada'];
        totalAlumnos = res['total_alumnos'];
        totalPresentes = res['total_presentes'];
        totalFaltas = res['total_faltas'];
        reporte = res['reporte'];
        cargando = false;
      });
      _fadeController.reset();
      _fadeController.forward();
    } catch (e) {
      print("Error al cargar asistencias: $e");
      setState(() {
        cargando = false;
      });
    }
  }

  // Seleccionar una fecha concreta (filtro principal del backend)
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

    await cargarAsistencias(fecha: fechaFormato);
  }

  void limpiarFiltros() {
    setState(() {
      filtroEstado = 'Todos';
      textoBusqueda = '';
      buscarController.clear();
    });
  }

  Future<void> exportarExcel() async {
    try {
      // Nota: el backend actual solo soporta exportación con fecha única o sin filtro.
      // Aquí usamos el método avanzado que acepta más parámetros, pero el backend debería implementarlos.
      await exportService.exportarAsistenciasAvanzado(
        widget.claseId,
        fechaInicio: null, // Podrías pasar fechaConsultada si quieres limitar
        fechaFin: null,
        estado: filtroEstado,
        busqueda: textoBusqueda,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reporte exportado correctamente")),
      );
    } catch (e) {
      print("Error exportando asistencias: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo exportar el reporte")),
      );
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    const colors = [_primary, _green, _orange, _purple, Colors.red, Colors.teal];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  @override
  void dispose() {
    buscarController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado local (nombre, correo, estado)
    final reporteFiltrado = reporte.where((item) {
      final nombre = item['nombre'].toString().toLowerCase();
      final correo = item['correo'].toString().toLowerCase();
      final busqueda = textoBusqueda.toLowerCase();
      final matchesBusqueda = nombre.contains(busqueda) || correo.contains(busqueda);

      if (filtroEstado != 'Todos') {
        final estadoItem = (item['estado'] ?? '').toString();
        return matchesBusqueda && estadoItem == filtroEstado;
      }
      return matchesBusqueda;
    }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(widget.nombreClase, style: const TextStyle(fontWeight: FontWeight.w700)),
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
              onRefresh: () => cargarAsistencias(),
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
                              "Fecha: ${fechaConsultada ?? 'Sin registros'}",
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statChip("Alumnos", totalAlumnos, Icons.people, _primaryLight, _primary),
                                _statChip("Presentes", totalPresentes, Icons.check_circle, _greenLight, _green),
                                _statChip("Faltas", totalFaltas, Icons.cancel, _redLight, _red),
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
                        // Filtro de estado mediante chips
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _filterChip("Todos", filtroEstado == "Todos"),
                              const SizedBox(width: 8),
                              _filterChip("Presente", filtroEstado == "Presente"),
                              const SizedBox(width: 8),
                              _filterChip("Falta", filtroEstado == "Falta"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Campo de búsqueda
                        TextField(
                          controller: buscarController,
                          decoration: InputDecoration(
                            hintText: "Buscar alumno",
                            prefixIcon: const Icon(Icons.search, color: _textGray),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: _cardColor,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          ),
                          onChanged: (value) => setState(() => textoBusqueda = value),
                        ),
                        const SizedBox(height: 8),
                        if (textoBusqueda.isNotEmpty || filtroEstado != "Todos")
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: limpiarFiltros,
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text("Limpiar filtros"),
                                style: TextButton.styleFrom(foregroundColor: _textGray),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Lista
                  Expanded(
                    child: reporteFiltrado.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, size: 48, color: _textGray),
                                const SizedBox(height: 12),
                                Text(
                                  textoBusqueda.isEmpty ? "No hay alumnos inscritos" : "No hay coincidencias",
                                  style: const TextStyle(color: _textGray),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: reporteFiltrado.length,
                            itemBuilder: (context, index) {
                              final alumno = reporteFiltrado[index];
                              final nombre = alumno['nombre'];
                              final correo = alumno['correo'];
                              final hora = alumno['hora'] ?? 'Sin registro';
                              final estado = alumno['estado'];
                              final esPresente = estado == 'Presente';

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
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 12, color: _textGray),
                                            const SizedBox(width: 4),
                                            Text("Hora: $hora", style: const TextStyle(fontSize: 12, color: _textGray)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: esPresente ? _greenLight : _redLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        estado,
                                        style: TextStyle(
                                          color: esPresente ? _green : _red,
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

  Widget _filterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => filtroEstado = label),
      backgroundColor: _cardColor,
      selectedColor: _primaryLight,
      checkmarkColor: _primary,
      labelStyle: TextStyle(color: selected ? _primary : _textGray),
      side: BorderSide(color: selected ? _primary : _borderColor),
    );
  }
}