import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
const Color _orangeLight  = Color(0xFFFFEDD5);

const _headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

class QrAsistenciaScreen extends StatefulWidget {
  final int    claseId;
  final String nombreClase;

  const QrAsistenciaScreen({
    super.key,
    required this.claseId,
    required this.nombreClase,
  });

  @override
  State<QrAsistenciaScreen> createState() => _QrAsistenciaScreenState();
}

class _QrAsistenciaScreenState extends State<QrAsistenciaScreen>
    with SingleTickerProviderStateMixin {
  final auth = AuthService();

  String? qrData;
  String  nombreAlumno = '';
  Timer?  _refreshTimer;
  Timer?  _countdownTimer;
  int     _secondsLeft = 30;
  bool    _regenerando = false;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();

    // Pulse animation for QR
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loadUser();
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

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombreAlumno = prefs.getString('nombre') ?? 'Alumno';
    });
  }

  Future<void> generarQr() async {
    final prefs    = await SharedPreferences.getInstance();
    final alumnoId = prefs.getInt('id');
    print("generarQr (asistencia) - alumnoId: $alumnoId");
    if (alumnoId == null) {
      print("No hay 'id' del alumno en SharedPreferences");
      return;
    }

    setState(() => _regenerando = true);

    try {
      final res = await auth.generarQr({
        "alumno_id":    alumnoId,
        "tipo_uso":     "asistencia",
        "referencia_id": widget.claseId,
      });

      print("RESPUESTA QR (asistencia): $res");

      setState(() {
        qrData = (res != null && res['codigo'] != null) ? res['codigo'] : null;
        _secondsLeft = 30;
        _regenerando = false;
      });

      if (res == null || res['codigo'] == null) {
        print("La respuesta no contiene 'codigo' para el QR (asistencia)");
      }
    } catch (e) {
      print("Error generando QR de asistencia (alumno): $e");
      setState(() => _regenerando = false);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ─── Countdown color ───────────────────────────────────────────────────────
  Color get _countdownColor {
    if (_secondsLeft > 15) return _green;
    if (_secondsLeft > 7)  return _orange;
    return const Color(0xFFEF4444);
  }

  String _initials(String s) {
    final parts = s.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
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
                // Badge tipo
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.person_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Alumno',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                // ── Instruction card ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD0D4FF)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: _primary, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Muestra este QR a tu maestro para registrar tu asistencia.',
                        style: TextStyle(
                            fontSize: 12,
                            color: _primary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 20),

                // ── QR Card ─────────────────────────────────────────────────
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

                    // Class + student info header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: _headerGradient,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(_initials(nombreAlumno),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nombreAlumno,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                Text(widget.nombreClase,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Asistencia',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),

                    // QR code area
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
                                    dataModuleShape:
                                        QrDataModuleShape.square,
                                    color: _textDark,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Countdown row
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
                        Icon(Icons.timer_outlined,
                            color: _countdownColor, size: 18),
                        const SizedBox(width: 8),
                        Text('El QR se actualiza en',
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
                          child: Text(
                            '$_secondsLeft s',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── Refresh button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _regenerando ? null : generarQr,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Regenerar QR',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Tips card ────────────────────────────────────────────────
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
                        const Text('Consejos',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _textDark)),
                        const SizedBox(height: 8),
                        _tip(Icons.brightness_high_outlined,
                            'Sube el brillo de tu pantalla para facilitar el escaneo.'),
                        _tip(Icons.qr_code_scanner_rounded,
                            'Mantén el QR estable mientras el maestro escanea.'),
                        _tip(Icons.timer_outlined,
                            'El código expira cada 30 segundos por seguridad.'),
                      ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: _textGray),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 11, color: _textGray, height: 1.4)),
        ),
      ]),
    );
  }
}