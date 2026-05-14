import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/services/auth_service.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const Color _primary      = Color(0xFF5B5FEF);
const Color _primaryLight = Color(0xFFEEF0FF);
const Color _bgColor      = Color(0xFFF5F5FA);
const Color _cardColor    = Colors.white;
const Color _textDark     = Color(0xFF1A1A2E);
const Color _textGray     = Color(0xFF9090A0);
const Color _borderColor  = Color(0xFFE8E8F0);
const Color _green        = Color(0xFF22C55E);
const Color _greenLight   = Color(0xFFDCFCE7);
const Color _orange       = Color(0xFFF97316);
const Color _red          = Color(0xFFEF4444);
const Color _purple       = Color(0xFF8B5CF6);
const Color _purpleLight  = Color(0xFFF3E8FF);

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

class QrAsistenciaMaestroScreen extends StatefulWidget {
  final int    claseId;
  final String nombreClase;

  const QrAsistenciaMaestroScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
  });

  @override
  State<QrAsistenciaMaestroScreen> createState() =>
      _QrAsistenciaMaestroScreenState();
}

class _QrAsistenciaMaestroScreenState
    extends State<QrAsistenciaMaestroScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();

  String? qrData;
  int     _secondsLeft = 30;
  bool    _regenerando = false;
  bool    _modoProyeccion = false;
  int     _escaneosRegistrados = 0;

  Timer? _refreshTimer;
  Timer? _countdownTimer;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    generarQr();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      generarQr();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        setState(() => _secondsLeft = 30);
      }
    });
  }

  Future<void> generarQr() async {
    setState(() => _regenerando = true);
    try {
      print("Generando QR...");
      print("claseId: ${widget.claseId}");

      final res = await auth.generarQr({
        "alumno_id":     null,
        "tipo_uso":      "asistencia",
        "referencia_id": widget.claseId,
      });

      print("RESPUESTA QR: $res");

      setState(() {
        qrData = res['codigo'];
        _secondsLeft = 30;
        _regenerando = false;
      });
    } catch (e) {
      print("Error generando QR de asistencia: $e");
      setState(() => _regenerando = false);
    }
  }

  Color get _countdownColor {
    if (_secondsLeft > 15) return _green;
    if (_secondsLeft > 7)  return _orange;
    return _red;
  }

  String _initials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ─── Modo proyección (pantalla completa) ───────────────────────────────────
  Widget _buildProjectionMode() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _modoProyeccion = false),
        child: Stack(children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A4E), Colors.black],
              ),
            ),
          ),
          Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.nombreClase,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Escanea para registrar asistencia',
                      style: TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 36),
                  if (qrData != null)
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.4),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData!,
                          size: 260,
                          eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: _textDark),
                          dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: _textDark),
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  // Countdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _countdownColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _countdownColor.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.timer_outlined,
                          color: _countdownColor, size: 18),
                      const SizedBox(width: 8),
                      Text('Se actualiza en $_secondsLeft s',
                          style: TextStyle(
                              color: _countdownColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  const Text('Toca para salir del modo proyección',
                      style:
                          TextStyle(color: Colors.white30, fontSize: 12)),
                ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_modoProyeccion) return _buildProjectionMode();

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: _headerGradient),
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('QR de Asistencia',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text(widget.nombreClase,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ]),
                ),
                // Projection mode button
                GestureDetector(
                  onTap: () => setState(() => _modoProyeccion = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(children: [
                      Icon(Icons.fullscreen_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Proyectar',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                // ── Stats row ────────────────────────────────────────────────
                Row(children: [
                  _miniStat('$_escaneosRegistrados', 'Escaneos',
                      Icons.qr_code_scanner_rounded, _greenLight, _green),
                  const SizedBox(width: 10),
                  _miniStat('30 s', 'Ciclo QR',
                      Icons.timer_outlined, _primaryLight, _primary),
                  const SizedBox(width: 10),
                  _miniStat('Activo', 'Estado',
                      Icons.circle, _purpleLight, _purple),
                ]),

                const SizedBox(height: 20),

                // ── QR Card ──────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(children: [

                    // Card header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: _headerGradient,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.class_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.nombreClase,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                const Text('Los alumnos escanean este QR',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11)),
                              ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(children: [
                            Icon(Icons.wifi_tethering_rounded,
                                color: Colors.white, size: 12),
                            SizedBox(width: 3),
                            Text('En vivo',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                    ),

                    // QR area
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: qrData == null || _regenerando
                          ? SizedBox(
                              height: 220,
                              child: Center(
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                          color: _primary),
                                      const SizedBox(height: 12),
                                      Text(
                                          _regenerando
                                              ? 'Actualizando QR...'
                                              : 'Generando QR...',
                                          style: const TextStyle(
                                              color: _textGray,
                                              fontSize: 13)),
                                    ]),
                              ),
                            )
                          : ScaleTransition(
                              scale: _pulseAnim,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: _borderColor, width: 1.5),
                                ),
                                child: QrImageView(
                                  data: qrData!,
                                  size: 200,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: _textDark,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Countdown
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _countdownColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _countdownColor.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.autorenew_rounded,
                            color: _countdownColor, size: 18),
                        const SizedBox(width: 8),
                        Text('Se actualiza automáticamente en',
                            style: TextStyle(
                                fontSize: 12,
                                color: _countdownColor,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _countdownColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$_secondsLeft s',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 12),

                // ── Action buttons ───────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _regenerando ? null : generarQr,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Regenerar',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(
                            color: _primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _modoProyeccion = true),
                      icon: const Icon(Icons.fullscreen_rounded,
                          size: 17),
                      label: const Text('Proyectar',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Info card ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cómo funciona',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _textDark)),
                        const SizedBox(height: 10),
                        _step('1', 'Muestra este QR a tus alumnos en clase.',
                            _primary),
                        _step('2',
                            'Cada alumno escanea el código con su app StarClass.',
                            _green),
                        _step('3',
                            'La asistencia se registra automáticamente.',
                            _purple),
                        _step('4',
                            'El QR cambia cada 30 s para evitar duplicados.',
                            _orange),
                      ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
      String val, String label, IconData icon, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: fg, size: 16),
              const SizedBox(height: 4),
              Text(val,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: fg)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: _textGray,
                      fontWeight: FontWeight.w500)),
            ]),
      ),
    );
  }

  Widget _step(String num, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(num,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: _textGray,
                  height: 1.4)),
        ),
      ]),
    );
  }
}