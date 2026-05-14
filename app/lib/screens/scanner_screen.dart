import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Design Tokens (mismos que maestro/alumno/login screen) ──────────────────
const Color _primary      = Color(0xFF4F46E5);
const Color _primaryDark  = Color(0xFF3730A3);
const Color _primaryLight = Color(0xFFEEF0FF);
const Color _accent       = Color(0xFF7C3AED);
const Color _textPrimary  = Color(0xFF111827);
const Color _textSecondary= Color(0xFF6B7280);
const Color _border       = Color(0xFFE5E7EB);
const Color _green        = Color(0xFF10B981);
const Color _greenLight   = Color(0xFFD1FAE5);
const Color _greenDark    = Color(0xFF059669);
const Color _red          = Color(0xFFEF4444);
const Color _redLight     = Color(0xFFFEE2E2);
const Color _orange       = Color(0xFFF97316);

const _grad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

// ─── Screen ──────────────────────────────────────────────────────────────────
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final auth        = AuthService();
  final _scannerCtrl = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool        _procesando = false;
  bool        _torch      = false;
  String      _statusMsg  = 'Apunta al código QR';
  _ScanStatus _status     = _ScanStatus.idle;

  List<Map<String, dynamic>> _clases           = [];
  Map<String, dynamic>?      _claseSeleccionada;
  bool                       _cargandoClases   = true;

  late AnimationController _cornerCtrl;
  late Animation<double>   _cornerAnim;

  @override
  void initState() {
    super.initState();
    _cornerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _cornerAnim = Tween<double>(begin: .88, end: 1.0)
        .animate(CurvedAnimation(parent: _cornerCtrl, curve: Curves.easeInOut));
    _cargarClases();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────
  Future<void> _cargarClases() async {
    final prefs = await SharedPreferences.getInstance();
    final rol   = prefs.getString('rol');
    final uid   = prefs.getInt('id');
    if (uid == null) return;
    try {
      dynamic res;
      if (rol == 'maestro') {
        res = await auth.obtenerClasesMaestro(uid);
      } else {
        res = await auth.obtenerClasesAlumno(uid);
      }
      _clases = List<Map<String, dynamic>>.from(res['clases']);
    } catch (_) {
      _clases = [];
    } finally {
      setState(() => _cargandoClases = false);
    }
  }

  Future<void> _procesarQr(String rawValue) async {
    if (_procesando) return;
    if (_claseSeleccionada == null) {
      setState(() {
        _status    = _ScanStatus.error;
        _statusMsg = 'Primero selecciona una clase';
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() { _status = _ScanStatus.idle; _statusMsg = 'Apunta al código QR'; });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _procesando = true;
      _status     = _ScanStatus.loading;
      _statusMsg  = 'Verificando código...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid   = prefs.getInt('id');
      final rol   = prefs.getString('rol');
      if (uid == null || rol == null) throw Exception('Usuario no encontrado');

      final res = await auth.validarQr({"codigo": rawValue});
      final qr  = res['qr'];
      String mensaje = '';

      if (qr['tipo_uso'] == 'asistencia' && rol == 'alumno') {
        await auth.registrarAsistencia({"clase_id": qr['referencia_id'], "alumno_id": uid});
        mensaje = 'Asistencia registrada';
      } else if (qr['tipo_uso'] == 'tarea' && rol == 'alumno') {
        await auth.entregarTarea({"tarea_id": qr['referencia_id'], "alumno_id": uid});
        mensaje = 'Tarea entregada correctamente';
      } else if (qr['tipo_uso'] == 'tarea' && rol == 'maestro') {
        await auth.entregarTarea({"tarea_id": qr['referencia_id'], "alumno_id": qr['alumno_id']});
        mensaje = 'Entrega registrada correctamente';
      } else {
        throw Exception('QR no válido');
      }

      HapticFeedback.heavyImpact();
      setState(() { _status = _ScanStatus.success; _statusMsg = mensaje; });
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      HapticFeedback.vibrate();
      setState(() {
        _status     = _ScanStatus.error;
        _statusMsg  = 'QR inválido o clase incorrecta';
        _procesando = false;
      });
      await Future.delayed(const Duration(milliseconds: 2000));
      if (mounted) setState(() {
        _status     = _ScanStatus.idle;
        _statusMsg  = 'Apunta al código QR';
        _procesando = false;
      });
    }
  }

  void _toggleTorch() {
    _scannerCtrl.toggleTorch();
    setState(() => _torch = !_torch);
  }

  // ─── Class selector sheet ──────────────────────────────────────────────────
  void _mostrarSelectorClases() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            )),
            // Header
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _primaryLight, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.class_rounded, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Selecciona una clase', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: _textPrimary)),
                Text('El QR se validará para esta clase', style: TextStyle(
                    fontSize: 12, color: _textSecondary)),
              ]),
            ]),
            const SizedBox(height: 20),

            if (_cargandoClases)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: _primary)),
              )
            else if (_clases.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Column(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                        color: _primaryLight, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.class_outlined, color: _primary, size: 26),
                  ),
                  const SizedBox(height: 12),
                  const Text('No tienes clases asignadas',
                      style: TextStyle(color: _textSecondary, fontSize: 14)),
                ])),
              )
            else
              ..._clases.map((clase) {
                final sel = _claseSeleccionada?['id'] == clase['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _claseSeleccionada = clase);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: sel ? _primaryLight : const Color(0xFFF8F8FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel ? _primary : _border,
                          width: sel ? 1.8 : 1),
                    ),
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: sel
                              ? _primary.withOpacity(.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.class_rounded,
                            color: sel ? _primary : _textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clase['nombre'] ?? 'Clase', style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14,
                              color: sel ? _primary : _textPrimary)),
                          if ((clase['descripcion'] ?? '').isNotEmpty)
                            Text(clase['descripcion'], style: const TextStyle(
                                fontSize: 11, color: _textSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      )),
                      if (sel)
                        Container(
                          width: 24, height: 24,
                          decoration: const BoxDecoration(
                              color: _primary, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        ),
                    ]),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── Computed ─────────────────────────────────────────────────────────────
  Color get _statusColor {
    switch (_status) {
      case _ScanStatus.success: return _green;
      case _ScanStatus.error:   return _red;
      case _ScanStatus.loading: return _primary;
      case _ScanStatus.idle:    return Colors.white;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case _ScanStatus.success: return Icons.check_circle_rounded;
      case _ScanStatus.error:   return Icons.error_rounded;
      default:                  return Icons.qr_code_scanner_rounded;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

        // ── Camera ──
        Positioned.fill(child: MobileScanner(
          controller: _scannerCtrl,
          onDetect: (capture) {
            for (final b in capture.barcodes) {
              final raw = b.rawValue;
              if (raw != null) { _procesarQr(raw); break; }
            }
          },
        )),

        // ── Dark overlay with cutout ──
        Positioned.fill(child: CustomPaint(
          painter: _ScannerOverlayPainter(
            borderColor: _statusColor, status: _status),
        )),

        // ── Animated corner brackets ──
        Center(child: AnimatedBuilder(
          animation: _cornerAnim,
          builder: (_, __) => Transform.scale(
            scale: _cornerAnim.value,
            child: SizedBox(width: 240, height: 240,
              child: CustomPaint(
                painter: _CornerPainter(color: _statusColor))),
          ),
        )),

        // ── TOP BAR (misma estructura que maestro/alumno screen) ──
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(.80), Colors.transparent],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
            child: Row(children: [
              // Back button — mismo estilo que menú en otras screens
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              // Title — mismo formato que otras screens
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Escanear QR', style: TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w800, letterSpacing: -.3)),
                  Text(
                    _claseSeleccionada != null
                        ? 'Clase: ${_claseSeleccionada!['nombre']}'
                        : 'Selecciona una clase primero',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              )),
              // Torch button
              GestureDetector(
                onTap: _toggleTorch,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _torch
                        ? const Color(0xFFF59E0B).withOpacity(.25)
                        : Colors.white.withOpacity(.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _torch
                          ? const Color(0xFFF59E0B).withOpacity(.5)
                          : Colors.white.withOpacity(.15),
                    ),
                  ),
                  child: Icon(
                    _torch
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    color: _torch ? const Color(0xFFF59E0B) : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ]),
          ),
        ),

        // ── BOTTOM PANEL ──
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(.88), Colors.transparent],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 32, 20, MediaQuery.of(context).padding.bottom + 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Class selector button — pill estilo consistente
              GestureDetector(
                onTap: _mostrarSelectorClases,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 13),
                  decoration: BoxDecoration(
                    color: _claseSeleccionada != null
                        ? _primary.withOpacity(.85)
                        : Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: _claseSeleccionada != null
                          ? _primary
                          : Colors.white.withOpacity(.25),
                      width: 1.5,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _claseSeleccionada != null
                          ? Icons.class_rounded
                          : Icons.add_rounded,
                      color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _claseSeleccionada != null
                          ? _claseSeleccionada!['nombre']
                          : 'Seleccionar clase',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_less_rounded,
                        color: Colors.white70, size: 18),
                  ]),
                ),
              ),

              const SizedBox(height: 16),

              // Status pill
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _statusColor == Colors.white
                      ? Colors.white.withOpacity(.10)
                      : _statusColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                      color: _statusColor.withOpacity(.35), width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _status == _ScanStatus.loading
                      ? SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _statusColor))
                      : Icon(_statusIcon, color: _statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(_statusMsg, style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
                ]),
              ),

              const SizedBox(height: 16),

              // Tips row / result banner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _status == _ScanStatus.idle ||
                        _status == _ScanStatus.loading
                    ? Row(
                        key: const ValueKey('tips'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _tip(Icons.wb_sunny_outlined, 'Buena luz'),
                          const SizedBox(width: 8),
                          _tip(Icons.crop_free_rounded, 'Centra el QR'),
                          const SizedBox(width: 8),
                          _tip(Icons.stay_current_portrait_rounded, 'Sin mover'),
                        ],
                      )
                    : _resultBanner(
                        key: const ValueKey('result'),
                        _status == _ScanStatus.success ? _green : _red,
                        _status == _ScanStatus.success
                            ? Icons.check_circle_outline_rounded
                            : Icons.warning_amber_rounded,
                        _status == _ScanStatus.success
                            ? '¡Listo! Cerrando...'
                            : 'Intenta con un QR válido',
                      ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _tip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white54, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _resultBanner(Color fg, IconData icon, String text, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: fg.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withOpacity(.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: fg, size: 16),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(
            color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  @override
  void dispose() {
    _cornerCtrl.dispose();
    _scannerCtrl.dispose();
    super.dispose();
  }
}

// ─── Enums & painters ─────────────────────────────────────────────────────────
enum _ScanStatus { idle, loading, success, error }

class _ScannerOverlayPainter extends CustomPainter {
  final Color       borderColor;
  final _ScanStatus status;
  const _ScannerOverlayPainter({required this.borderColor, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    const cw   = 240.0;
    const ch   = 240.0;
    final l    = (size.width  - cw) / 2;
    final t    = (size.height - ch) / 2;
    final rect = Rect.fromLTWH(l, t, cw, ch);
    final rr   = RRect.fromRectAndRadius(rect, const Radius.circular(20));

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(rr)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withOpacity(.65),
    );

    if (status == _ScanStatus.success || status == _ScanStatus.error) {
      canvas.drawRRect(rr, Paint()
        ..color       = borderColor.withOpacity(.5)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter  = const MaskFilter.blur(BlurStyle.outer, 8));
    }
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.borderColor != borderColor || old.status != status;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color       = color
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap   = StrokeCap.round;

    const l = 28.0;
    // top-left
    canvas.drawLine(Offset(0, l), Offset.zero, p);
    canvas.drawLine(Offset.zero, Offset(l, 0), p);
    // top-right
    canvas.drawLine(Offset(size.width - l, 0), Offset(size.width, 0), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, l), p);
    // bottom-left
    canvas.drawLine(Offset(0, size.height - l), Offset(0, size.height), p);
    canvas.drawLine(Offset(0, size.height), Offset(l, size.height), p);
    // bottom-right
    canvas.drawLine(Offset(size.width - l, size.height),
        Offset(size.width, size.height), p);
    canvas.drawLine(Offset(size.width, size.height - l),
        Offset(size.width, size.height), p);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}