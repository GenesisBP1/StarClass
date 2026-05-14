import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/auth_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const Color _primary       = Color(0xFF4F46E5);
const Color _primaryDark   = Color(0xFF3730A3);
const Color _primaryLight  = Color(0xFFEEF0FF);
const Color _accent        = Color(0xFF7C3AED);
const Color _bg            = Color(0xFFF8F8FC);
const Color _surface       = Colors.white;
const Color _textPrimary   = Color(0xFF111827);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textHint      = Color(0xFFB0B4C8);
const Color _border        = Color(0xFFE5E7EB);
const Color _borderFocus   = Color(0xFF4F46E5);
const Color _errorColor    = Color(0xFFEF4444);
const Color _successColor  = Color(0xFF10B981);

const _grad = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
);

// ─── Screen ──────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final auth                     = AuthService();
  final _formKey                 = GlobalKey<FormState>();
  final nombreCtrl               = TextEditingController();
  final correoCtrl               = TextEditingController();
  final passwordCtrl             = TextEditingController();
  final confirmCtrl              = TextEditingController();
  final FocusNode _correoFocus   = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLogin         = true;
  bool _obscurePwd      = true;
  bool _obscureConfirm  = true;
  bool _loading         = false;
  String _rol           = 'alumno';

  late AnimationController _tabCtrl;
  late AnimationController _formCtrl;
  late Animation<double>   _formFade;
  late Animation<Offset>   _formSlide;

  @override
  void initState() {
    super.initState();
    _tabCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));
    _formCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 320));
    _formFade  = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut));
    _formCtrl.forward();
  }

  void _switchMode(bool toLogin) {
    if (_isLogin == toLogin) return;
    HapticFeedback.selectionClick();
    _formCtrl.reverse().then((_) {
      setState(() {
        _isLogin = toLogin;
        _clearFields();
      });
      _formCtrl.forward();
    });
  }

  void _clearFields() {
    nombreCtrl.clear();
    correoCtrl.clear();
    passwordCtrl.clear();
    confirmCtrl.clear();
    _rol = 'alumno';
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _doLogin();
      } else {
        await _doRegister();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doLogin() async {
    final res  = await auth.login(
        correoCtrl.text.trim(), passwordCtrl.text.trim());
    final user = res['user'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('id', user['id']);
    await prefs.setString('correo',  user['correo']);
    await prefs.setString('nombre',  user['nombre']);
    await prefs.setString('rol',     user['rol']);
    await prefs.setString('token',   res['token']);
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context, user['rol'] == 'maestro' ? '/maestro' : '/alumno');
  }

  Future<void> _doRegister() async {
    if (passwordCtrl.text != confirmCtrl.text) {
      _showError('Las contraseñas no coinciden'); return;
    }
    await auth.register({
      "nombre":   nombreCtrl.text.trim(),
      "correo":   correoCtrl.text.trim(),
      "password": passwordCtrl.text.trim(),
      "rol":      _rol,
    });
    if (!mounted) return;
    _showSuccess('Cuenta creada. ¡Inicia sesión!');
    _switchMode(true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: _errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: _successColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: _bg,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottom + 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _formFade,
                    child: SlideTransition(
                      position: _formSlide,
                      child: _isLogin ? _buildLoginFields()
                                      : _buildRegisterFields(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSubmitButton(),
                ),
                const SizedBox(height: 20),
                _buildSwitchRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Hero header ─────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(gradient: _grad),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 36, 24, 0),
      child: Column(children: [
        // Logo
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.18),
                  blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: const Icon(Icons.school_rounded,
              color: _primary, size: 38),
        ),
        const SizedBox(height: 14),
        const Text('StarClass',
            style: TextStyle(color: Colors.white,
                fontSize: 28, fontWeight: FontWeight.w800,
                letterSpacing: -.5)),
        const SizedBox(height: 4),
        const Text('Tu aula conectada',
            style: TextStyle(color: Colors.white60, fontSize: 14)),
        const SizedBox(height: 28),

        // Tab bar
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(children: [
            _tab('Iniciar sesión', _isLogin, () => _switchMode(true)),
            _tab('Registrarse',   !_isLogin, () => _switchMode(false)),
          ]),
        ),
        const SizedBox(height: 0),

        // Curved bottom
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          margin: const EdgeInsets.only(top: 24),
        ),
      ]),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(.1),
                      blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: active ? _primary : Colors.white.withOpacity(.75),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  // ─── Login fields ─────────────────────────────────────────────────────────
  Widget _buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Demo hint card
        _demoCard(),
        const SizedBox(height: 20),
        _label('Correo institucional'),
        const SizedBox(height: 6),
        _inputField(
          controller: correoCtrl,
          focusNode: _correoFocus,
          nextFocus: _passwordFocus,
          hint: 'alumno@universidad.edu.mx',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              (v?.isEmpty ?? true) ? 'Ingresa tu correo' : null,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('Contraseña'),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('¿Olvidaste tu contraseña?',
                  style: TextStyle(fontSize: 12,
                      color: _primary, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _inputField(
          controller: passwordCtrl,
          focusNode: _passwordFocus,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePwd,
          onToggleObscure: () =>
              setState(() => _obscurePwd = !_obscurePwd),
          validator: (v) =>
              (v?.isEmpty ?? true) ? 'Ingresa tu contraseña' : null,
          textInputAction: TextInputAction.done,
          onSubmit: (_) => _submit(),
        ),
      ],
    );
  }

  Widget _demoCard() {
    final accounts = [
      {'rol': 'Alumno',  'correo': 'sofia.ramirez@universidad.edu.mx'},
      {'rol': 'Maestro', 'correo': 'prof.hernandez@universidad.edu.mx'},
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withOpacity(.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.info_outline_rounded, size: 14, color: _primary),
            SizedBox(width: 6),
            Text('Cuentas demo', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _primary)),
          ]),
          const SizedBox(height: 10),
          ...accounts.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: Text(a['rol']!, style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _textPrimary)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(a['correo']!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _textSecondary))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  correoCtrl.text   = a['correo']!;
                  passwordCtrl.text = '12345678';
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Usar', style: TextStyle(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  // ─── Register fields ──────────────────────────────────────────────────────
  Widget _buildRegisterFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rol selector
        _label('¿Cómo deseas ingresar?'),
        const SizedBox(height: 10),
        Row(children: [
          _rolCard('alumno', 'Alumno',
              'Únete a clases y entrega tareas',
              Icons.person_rounded),
          const SizedBox(width: 10),
          _rolCard('maestro', 'Maestro',
              'Crea clases y gestiona alumnos',
              Icons.school_rounded),
        ]),
        const SizedBox(height: 20),

        _label('Nombre completo'),
        const SizedBox(height: 6),
        _inputField(
          controller: nombreCtrl,
          hint: 'Sofía Ramírez Torres',
          icon: Icons.person_outline_rounded,
          validator: (v) =>
              (v?.isEmpty ?? true) ? 'Ingresa tu nombre' : null,
        ),
        const SizedBox(height: 16),

        _label('Correo institucional'),
        const SizedBox(height: 6),
        _inputField(
          controller: correoCtrl,
          hint: 'nombre@universidad.edu.mx',
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (v) =>
              (v?.isEmpty ?? true) ? 'Ingresa tu correo' : null,
        ),
        const SizedBox(height: 16),

        // 2 password fields side note
        Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Contraseña'),
              const SizedBox(height: 6),
              _inputField(
                controller: passwordCtrl,
                hint: 'Mín. 8 caracteres',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePwd,
                onToggleObscure: () =>
                    setState(() => _obscurePwd = !_obscurePwd),
                validator: (v) => (v?.length ?? 0) < 8
                    ? 'Mínimo 8 caracteres' : null,
              ),
            ],
          )),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Confirmar'),
              const SizedBox(height: 6),
              _inputField(
                controller: confirmCtrl,
                hint: 'Repite',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) => v != passwordCtrl.text
                    ? 'No coincide' : null,
                textInputAction: TextInputAction.done,
                onSubmit: (_) => _submit(),
              ),
            ],
          )),
        ]),
      ],
    );
  }

  Widget _rolCard(String value, String label, String desc, IconData icon) {
    final sel = _rol == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { HapticFeedback.selectionClick();
            setState(() => _rol = value); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sel ? _primaryLight : _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: sel ? _primary : _border,
                width: sel ? 1.8 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: sel ? _primary : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: sel ? Colors.white : _textSecondary,
                    size: 20),
              ),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: sel ? _primary : _textPrimary)),
              const SizedBox(height: 3),
              Text(desc, style: const TextStyle(
                  fontSize: 10, color: _textSecondary, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Submit button ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primary.withOpacity(.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(
                _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    letterSpacing: .2),
              ),
      ),
    );
  }

  Widget _buildSwitchRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? ',
          style: const TextStyle(color: _textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => _switchMode(!_isLogin),
          child: Text(
            _isLogin ? 'Regístrate' : 'Inicia sesión',
            style: const TextStyle(
                color: _primary, fontSize: 14,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w600, color: _textPrimary));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmit ?? (_) {
        if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
      },
      validator: validator,
      style: const TextStyle(fontSize: 14,
          color: _textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textHint, fontSize: 14),
        prefixIcon: Icon(icon, color: _textSecondary, size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined
                           : Icons.visibility_outlined,
                  color: _textSecondary, size: 20),
                onPressed: onToggleObscure)
            : null,
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _borderFocus, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _errorColor)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _errorColor, width: 2)),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose(); _formCtrl.dispose();
    nombreCtrl.dispose(); correoCtrl.dispose();
    passwordCtrl.dispose(); confirmCtrl.dispose();
    _correoFocus.dispose(); _passwordFocus.dispose();
    super.dispose();
  }
}