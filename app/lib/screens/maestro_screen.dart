import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';
import 'tareas_screen.dart';
import 'scanner_screen.dart';
import 'asistencias_screen.dart';
import 'qr_asistencia_maestro_screen.dart';
import 'login_screen.dart';
import 'alumnos_clase_screen.dart';
import 'reporte_tareas_screen.dart';

// ─── Colors & Design Tokens ──────────────────────────────────────────────────
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
const Color _purple       = Color(0xFF8B5CF6);
const Color _purpleLight  = Color(0xFFF3E8FF);
const Color _orange       = Color(0xFFF97316);
const Color _orangeLight  = Color(0xFFFFEDD5);

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

class MaestroScreen extends StatefulWidget {
  const MaestroScreen({super.key});

  @override
  State<MaestroScreen> createState() => _MaestroScreenState();
}

class _MaestroScreenState extends State<MaestroScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final editNombreController = TextEditingController();
  final editDescController = TextEditingController();

  List clases = [];
  bool cargando = true;
  int _navIndex = 0;
  int? selectedClaseIdx;
  String nombreUsuario = '';
  String correoUsuario = '';
  String rolUsuario = 'maestro';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUser();
    cargarClases();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombreUsuario = prefs.getString('nombre') ?? 'Maestro';
      correoUsuario = prefs.getString('correo') ?? '';
      rolUsuario = prefs.getString('rol') ?? 'maestro';
    });
  }

  Future<void> cargarClases() async {
    final prefs = await SharedPreferences.getInstance();
    final maestroId = prefs.getInt('id');
    if (maestroId == null) {
      setState(() => cargando = false);
      return;
    }
    try {
      final res = await auth.obtenerClasesMaestro(maestroId);
      setState(() {
        clases = res['clases'];
        cargando = false;
        selectedClaseIdx ??= clases.isNotEmpty ? 0 : null;
      });
      _fadeController.reset();
      _fadeController.forward();
    } catch (e) {
      print("Error cargando clases: $e");
      setState(() => cargando = false);
    }
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> crearClase() async {
    final prefs = await SharedPreferences.getInstance();
    final maestroId = prefs.getInt('id');
    if (maestroId == null) return;
    if (nombreController.text.trim().isEmpty) {
      _snack("El nombre de la clase es obligatorio");
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
      _snack("Clase creada correctamente");
    } catch (_) {
      _snack("No se pudo crear la clase");
    }
  }

  Future<void> editarClase(int claseId) async {
    if (editNombreController.text.trim().isEmpty) {
      _snack("El nombre es obligatorio");
      return;
    }
    try {
      await auth.actualizarClase(claseId, {
        "nombre": editNombreController.text.trim(),
        "descripcion": editDescController.text.trim(),
      });
      await cargarClases();
      _snack("Clase actualizada");
    } catch (_) {
      _snack("No se pudo actualizar la clase");
    }
  }

  Future<void> eliminarClase(int claseId) async {
    try {
      await auth.eliminarClase(claseId);
      setState(() {
        clases.removeWhere((c) => c['id'] == claseId);
        selectedClaseIdx = clases.isNotEmpty ? 0 : null;
      });
      _snack("Clase eliminada");
    } catch (_) {
      _snack("No se pudo eliminar la clase");
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Sheets / Dialogs ───────────────────────────────────────────────────
  void _showCreateSheet() {
    nombreController.clear();
    descripcionController.clear();
    _openClassSheet(
      title: 'Crear nueva clase',
      btnLabel: 'Crear clase',
      nc: nombreController,
      dc: descripcionController,
      onSave: () async {
        Navigator.pop(context);
        await crearClase();
      },
    );
  }

  void _showEditSheet(Map clase) {
    editNombreController.text = clase['nombre'] ?? '';
    editDescController.text = clase['descripcion'] ?? '';
    _openClassSheet(
      title: 'Editar clase',
      btnLabel: 'Guardar cambios',
      nc: editNombreController,
      dc: editDescController,
      onSave: () async {
        Navigator.pop(context);
        await editarClase(clase['id']);
      },
    );
  }

  void _openClassSheet({
    required String title,
    required String btnLabel,
    required TextEditingController nc,
    required TextEditingController dc,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark)),
              const SizedBox(height: 16),
              _field(nc, 'Nombre de la clase', Icons.class_outlined,
                  'Ej. Cálculo Diferencial'),
              const SizedBox(height: 12),
              _field(dc, 'Descripción', Icons.notes_rounded,
                  'Ej. Matemáticas · Grupo A'),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textGray,
                      side: const BorderSide(color: _borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _primaryBtn(btnLabel, onSave)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(Map clase) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                  color: _redLight, shape: BoxShape.circle),
              child:
                  const Icon(Icons.delete_outline_rounded, color: _red, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Eliminar clase',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 8),
            Text(
              '¿Eliminar "${clase['nombre']}"? Esta acción no se puede deshacer.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGray, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textGray,
                    side: const BorderSide(color: _borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await eliminarClase(clase['id']);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Eliminar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgColor,
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Sidebar / Drawer ──────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: const BoxDecoration(gradient: _headerGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(_initials(nombreUsuario),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24)),
                ),
                const SizedBox(height: 12),
                Text(nombreUsuario,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(correoUsuario,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('👨‍🏫 Maestro',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(Icons.class_rounded, 'Mis Clases', true, () {
            Navigator.pop(context);
            setState(() => _navIndex = 0);
          }),
          _drawerItem(Icons.qr_code_scanner_rounded, 'Escáner QR', false, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScannerScreen()));
          }),
          _drawerItem(Icons.event_available_rounded, 'Asistencias', false, () {
            Navigator.pop(context);
            if (clases.isNotEmpty) {
              final c = clases[selectedClaseIdx ?? 0];
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AsistenciasScreen(
                          claseId: c['id'], nombreClase: c['nombre'])));
            }
          }),
          _drawerItem(Icons.add_circle_outline_rounded, 'Crear Clase', false, () {
            Navigator.pop(context);
            _showCreateSheet();
          }),
          const Spacer(),
          const Divider(color: _borderColor, height: 1),
          const SizedBox(height: 4),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: _redLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded, color: _red, size: 18),
            ),
            title: const Text('Cerrar sesión',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _red)),
            onTap: _logout,
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _drawerItem(
      IconData icon, String label, bool active, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? _primaryLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: active ? _primary : _textGray, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: active ? _primary : _textDark)),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: cargarClases,
      color: _primary,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildStatsRow(),
          ),
        ),
        SliverToBoxAdapter(child: _buildCreateBanner()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: const Text('Mis Clases',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark)),
          ),
        ),
        if (cargando)
          const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _primary)))
        else if (clases.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.class_outlined, size: 52, color: _borderColor),
                  const SizedBox(height: 12),
                  const Text('No tienes clases creadas.',
                      style: TextStyle(color: _textGray)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 180,
                    child: _primaryBtn('Crear primera clase', _showCreateSheet),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildClaseCard(clases[i]),
                ),
                childCount: clases.length,
              ),
            ),
          ),
      ]),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: _headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
      child: Row(children: [
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child:
                const Icon(Icons.school_rounded, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('StarClass',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              Text('Maestro · $nombreUsuario',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(_initials(nombreUsuario),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Row(children: [
      _statChip('Clases', clases.length, Icons.class_rounded, _primaryLight, _primary),
      const SizedBox(width: 10),
      _statChip('Escaneos', 0, Icons.qr_code_scanner_rounded, _greenLight, _green),
      const SizedBox(width: 10),
      _statChip('Asistencias', 0, Icons.event_available_rounded, _purpleLight, _purple),
    ]);
  }

  Widget _statChip(String label, int value, IconData icon, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 6),
            Text(
              "$label: $value",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Create banner ─────────────────────────────────────────────────────────
  Widget _buildCreateBanner() {
    return GestureDetector(
      onTap: _showCreateSheet,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear nueva clase',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text('Genera un código automáticamente',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 22),
        ]),
      ),
    );
  }

  // ─── Clase card ────────────────────────────────────────────────────────────
  Widget _buildClaseCard(Map clase) {
    return Container(
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
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            _avatarChip(clase['nombre'] ?? 'CL', 44, 18),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clase['nombre'] ?? 'Clase',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _textDark)),
                  const SizedBox(height: 4),
                  Text(
                    clase['descripcion'] ?? 'Sin descripción',
                    style: const TextStyle(fontSize: 12, color: _textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (clase['codigo_clase'] != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(clase['codigo_clase'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _primary,
                        letterSpacing: 1.2)),
              ),
          ]),
        ),
        const Divider(color: _borderColor, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(children: [
            _actionChip(Icons.assignment_outlined, 'Tareas', _primaryLight,
                _primary, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TareasScreen(
                    claseId: clase['id'],
                    nombreClase: clase['nombre'],
                    esMaestro: true,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _actionChip(Icons.qr_code_rounded, 'QR', _greenLight, _green, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrAsistenciaMaestroScreen(
                    claseId: clase['id'],
                    nombreClase: clase['nombre'],
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _actionChip(Icons.event_available_rounded, 'Lista', _purpleLight,
                _purple, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AsistenciasScreen(
                    claseId: clase['id'],
                    nombreClase: clase['nombre'],
                  ),
                ),
              );
            }),
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: _textGray),
              onSelected: (value) async {
                if (value == 'alumnos') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlumnosClaseScreen(
                        claseId: clase['id'],
                        nombreClase: clase['nombre'],
                      ),
                    ),
                  );
                } else if (value == 'reporte_tareas') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReporteTareasScreen(
                        claseId: clase['id'],
                        nombreClase: clase['nombre'],
                      ),
                    ),
                  );
                } else if (value == 'editar') {
                  _showEditSheet(clase);
                } else if (value == 'eliminar') {
                  _showDeleteConfirm(clase);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'alumnos',
                  child: Row(children: [
                    Icon(Icons.people_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Ver alumnos'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'reporte_tareas',
                  child: Row(children: [
                    Icon(Icons.assessment_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Reporte de tareas'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Eliminar'),
                  ]),
                ),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _actionChip(IconData icon, String label, Color bg, Color fg,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ─── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const items = [
      ('Clases', Icons.class_rounded, Icons.class_outlined),
      ('Escáner', Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_outlined),
      ('Asistencia', Icons.event_available_rounded, Icons.event_available_outlined),
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = _navIndex == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (i == 1) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScannerScreen()));
                } else if (i == 2 && clases.isNotEmpty) {
                  final c = clases[selectedClaseIdx ?? 0];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AsistenciasScreen(
                          claseId: c['id'],
                          nombreClase: c['nombre']),
                    ),
                  );
                } else {
                  setState(() => _navIndex = i);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 40,
                    height: 32,
                    decoration: BoxDecoration(
                      color: active ? _primaryLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      active ? items[i].$2 : items[i].$3,
                      color: active ? _primary : _textGray,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(items[i].$1,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? _primary : _textGray)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  String _initials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _colorForName(String s) {
    const cols = [
      _primary, _green, _purple, _orange, Colors.red, Colors.teal,
    ];
    return s.isEmpty ? cols[0] : cols[s.codeUnitAt(0) % cols.length];
  }

  Widget _avatarChip(String name, double size, double fs) {
    final color = _colorForName(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      alignment: Alignment.center,
      child: Text(_initials(name),
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: fs)),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textDark)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textGray, fontSize: 14),
            prefixIcon: Icon(icon, color: _textGray, size: 20),
            filled: true,
            fillColor: _bgColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.8)),
          ),
        ),
      ],
    );
  }

  Widget _primaryBtn(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    editNombreController.dispose();
    editDescController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}