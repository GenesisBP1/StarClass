import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';
import 'tareas_screen.dart';
import 'qr_asistencia_screen.dart';
import 'scanner_screen.dart';
import 'login_screen.dart';

// ─── Colors & Design Tokens (mismos que MaestroScreen) ────────────────────────
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

class AlumnoScreen extends StatefulWidget {
  const AlumnoScreen({super.key});

  @override
  State<AlumnoScreen> createState() => _AlumnoScreenState();
}

class _AlumnoScreenState extends State<AlumnoScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();
  final codigoController = TextEditingController();

  List clases = [];
  bool cargando = true;
  int? selectedClaseIdx;
  String nombreUsuario = '';
  String correoUsuario = '';

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
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombreUsuario = prefs.getString('nombre') ?? 'Alumno';
      correoUsuario = prefs.getString('correo') ?? '';
    });
  }

  Future<void> cargarClases() async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');
    if (alumnoId == null) {
      setState(() => cargando = false);
      return;
    }
    try {
      final res = await auth.obtenerClasesAlumno(alumnoId);
      setState(() {
        clases = res['clases'];
        cargando = false;
        selectedClaseIdx ??= clases.isNotEmpty ? 0 : null;
      });
      _fadeController.reset();
      _fadeController.forward();
    } catch (e) {
      setState(() => cargando = false);
    }
  }

  Future<void> unirseClase() async {
    final prefs = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');
    if (alumnoId == null) return;
    try {
      await auth.unirseClase({
        "codigo_clase": codigoController.text.trim().toUpperCase(),
        "alumno_id": alumnoId,
      });
      codigoController.clear();
      await cargarClases();
      _snack("¡Te uniste a la clase!");
    } catch (_) {
      _snack("No se pudo unir a la clase. Verifica el código.");
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showJoinSheet() {
    codigoController.clear();
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
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.add_link_rounded, color: _primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unirse a clase',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _textDark)),
                    Text('Ingresa el código de tu maestro',
                        style: TextStyle(fontSize: 12, color: _textGray)),
                  ],
                ),
              ]),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Código de clase',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codigoController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: _textDark),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'XXXXX',
                      hintStyle: TextStyle(
                          color: _borderColor,
                          fontSize: 20,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w800),
                      filled: true,
                      fillColor: _bgColor,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary, width: 2)),
                    ),
                  ),
                ],
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                      await unirseClase();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Unirme',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
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
                  child: const Text('🎓 Alumno',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _drawerItem(Icons.class_rounded, 'Mis Clases', true,
              () => Navigator.pop(context)),
          _drawerItem(Icons.qr_code_scanner_rounded, 'Escanear QR', false, () {
            Navigator.pop(context);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScannerScreen()));
          }),
          _drawerItem(Icons.add_link_rounded, 'Unirse a Clase', false, () {
            Navigator.pop(context);
            _showJoinSheet();
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
        SliverToBoxAdapter(child: _buildJoinBanner()),
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
                  const Icon(Icons.school_outlined,
                      size: 52, color: _borderColor),
                  const SizedBox(height: 12),
                  const Text('Aún no te has unido a ninguna clase.',
                      style: TextStyle(color: _textGray, fontSize: 14)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 180,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _showJoinSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Unirse a clase',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
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
              Text('Alumno · $nombreUsuario',
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

  Widget _buildStatsRow() {
    return Row(children: [
      _statCard(clases.length.toString(), 'Clases', Icons.class_rounded,
          _primaryLight, _primary),
      const SizedBox(width: 10),
      _statCard('0', 'Tareas', Icons.assignment_outlined, _orangeLight,
          _orange),
      const SizedBox(width: 10),
      _statCard('0', 'Asistencias', Icons.event_available_rounded, _greenLight,
          _green),
    ]);
  }

  Widget _statCard(String val, String label, IconData icon, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(height: 6),
            Text(val,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: fg)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _textGray, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinBanner() {
    return GestureDetector(
      onTap: _showJoinSheet,
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
            child: const Icon(Icons.add_link_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unirse a una clase',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text('Ingresa el código de 5 dígitos de tu maestro',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 22),
        ]),
      ),
    );
  }

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
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: _textGray),
                    const SizedBox(width: 4),
                    Text(
                      'Unido: ${clase['fecha_union'] ?? 'Hoy'}',
                      style: const TextStyle(fontSize: 10, color: _textGray),
                    ),
                  ]),
                ],
              ),
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
                    esMaestro: false,
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _actionChip(Icons.qr_code_rounded, 'Mi QR', _greenLight, _green, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QrAsistenciaScreen(
                    claseId: clase['id'],
                    nombreClase: clase['nombre'],
                  ),
                ),
              );
            }),
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

  Widget _buildBottomNav() {
    const items = [
      ('Clases', Icons.class_rounded, Icons.class_outlined),
      ('Escáner', Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_outlined),
      ('Perfil', Icons.person_rounded, Icons.person_outline_rounded),
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
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ScannerScreen()));
                } else if (i == 2) {
                  _scaffoldKey.currentState?.openDrawer();
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

  int _navIndex = 0;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _initials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _colorForName(String s) {
    const cols = [
      Color(0xFF5B5FEF),
      Color(0xFF22C55E),
      Color(0xFF8B5CF6),
      Color(0xFFF97316),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
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

  @override
  void dispose() {
    codigoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}