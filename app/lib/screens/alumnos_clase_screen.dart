import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';

// ─── Colors & Design Tokens (mismos que el resto de la app) ──────────────────
const Color _primary      = Color(0xFF5B5FEF);
const Color _primaryLight = Color(0xFFEEF0FF);
const Color _bgColor      = Color(0xFFF8F9FF);
const Color _cardColor    = Colors.white;
const Color _textDark     = Color(0xFF1E293B);
const Color _textGray     = Color(0xFF64748B);
const Color _borderColor  = Color(0xFFE2E8F0);
const Color _green        = Color(0xFF22C55E);
const Color _greenLight   = Color(0xFFDCFCE7);
const Color _purple       = Color(0xFF8B5CF6);
const Color _purpleLight  = Color(0xFFF3E8FF);

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

class AlumnosClaseScreen extends StatefulWidget {
  final int claseId;
  final String nombreClase;

  const AlumnosClaseScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
  });

  @override
  State<AlumnosClaseScreen> createState() => _AlumnosClaseScreenState();
}

class _AlumnosClaseScreenState extends State<AlumnosClaseScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();

  List alumnos = [];
  bool cargando = true;
  String? errorMsg;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    cargarAlumnos();
  }

  Future<void> cargarAlumnos() async {
    setState(() {
      cargando = true;
      errorMsg = null;
    });
    try {
      final res = await auth.obtenerAlumnosClase(widget.claseId);
      setState(() {
        alumnos = res['alumnos'];
        cargando = false;
      });
      _fadeController.reset();
      _fadeController.forward();
    } catch (e) {
      print("Error cargando alumnos: $e");
      setState(() {
        errorMsg = "No se pudieron cargar los alumnos";
        cargando = false;
      });
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
    const colors = [
      Color(0xFF5B5FEF),
      Color(0xFF22C55E),
      Color(0xFF8B5CF6),
      Color(0xFFF97316),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
    ];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(widget.nombreClase, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _headerGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: cargarAlumnos,
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(errorMsg!, style: const TextStyle(color: _textGray)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: cargarAlumnos,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : alumnos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: _textGray),
                          SizedBox(height: 12),
                          Text('No hay alumnos inscritos', style: TextStyle(color: _textGray)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargarAlumnos,
                      color: _primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: alumnos.length,
                        itemBuilder: (context, index) {
                          final alumno = alumnos[index];
                          final nombre = alumno['nombre'] ?? 'Sin nombre';
                          final correo = alumno['correo'] ?? 'Sin correo';
                          final fechaUnion = alumno['fecha_union'] ?? 'Fecha desconocida';

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
                                  child: Text(_initials(nombre),
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                title: Text(
                                  nombre,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(correo,
                                        style: const TextStyle(fontSize: 12, color: _textGray)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 12, color: _textGray),
                                        const SizedBox(width: 4),
                                        Text('Se unió: $fechaUnion',
                                            style: const TextStyle(fontSize: 10, color: _textGray)),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _greenLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Activo',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _green)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}