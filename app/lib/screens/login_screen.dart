import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmarPasswordController = TextEditingController();

  // Services
  final auth = AuthService();

  // State
  bool esRegistro = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String rolSeleccionado = 'alumno';

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Demo accounts
  final List<Map<String, String>> demoAccounts = [
    {'rol': 'Alumno', 'correo': 'sofia.ramirez@universidad.edu.mx'},
    {'rol': 'Maestro', 'correo': 'prof.hernandez@universidad.edu.mx'},
  ];

  static const Color _primary = Color(0xFF5B5FEF);
  static const Color _primaryLight = Color(0xFF7B7FF5);
  static const Color _bgColor = Color(0xFFF5F5FA);
  static const Color _cardColor = Colors.white;
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textGray = Color(0xFF9090A0);
  static const Color _borderColor = Color(0xFFE8E8F0);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  void _switchMode(bool toRegistro) {
    if (esRegistro == toRegistro) return;
    _animController.reset();
    setState(() {
      esRegistro = toRegistro;
      nombreController.clear();
      correoController.clear();
      passwordController.clear();
      confirmarPasswordController.clear();
      rolSeleccionado = 'alumno';
    });
    _animController.forward();
  }

  Future<void> login() async {
    try {
      final res = await auth.login(
        correoController.text.trim(),
        passwordController.text.trim(),
      );
      final user = res['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('id', user['id']);
      await prefs.setString('correo', user['correo']);
      await prefs.setString('nombre', user['nombre']);
      await prefs.setString('rol', user['rol']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login exitoso")),
      );
      Navigator.pushReplacementNamed(
        context,
        user['rol'] == 'maestro' ? '/maestro' : '/alumno',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Credenciales incorrectas")),
      );
    }
  }

  Future<void> registrar() async {
    if (nombreController.text.trim().isEmpty ||
        correoController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }
    if (passwordController.text != confirmarPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }
    try {
      await auth.register({
        "nombre": nombreController.text.trim(),
        "correo": correoController.text.trim(),
        "password": passwordController.text.trim(),
        "rol": rolSeleccionado,
      });
      if (!mounted) return;
      _switchMode(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario registrado correctamente")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo registrar el usuario")),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    confirmarPasswordController.dispose();
    super.dispose();
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded, color: _primary, size: 32),
          ),
          const SizedBox(height: 10),
          const Text(
            'StarClass',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'Tu aula conectada',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          // Tab switcher
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTab('Iniciar sesión', !esRegistro, () => _switchMode(false)),
                _buildTab('Registrarse', esRegistro, () => _switchMode(true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? _primary : Colors.white,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D4FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, size: 16, color: _primary),
              SizedBox(width: 6),
              Text(
                'Cuentas de demostración',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...demoAccounts.map(
            (acc) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  _rolChip(acc['rol']!),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      acc['correo']!,
                      style: const TextStyle(fontSize: 12, color: _textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      correoController.text = acc['correo']!;
                      passwordController.text = '12345678';
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Usar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rolChip(String rol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Text(
        rol,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textDark),
      ),
    );
  }

  Widget _buildRolSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cómo deseas ingresar?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _rolCard(
              'alumno',
              'Alumno',
              'Únete a clases y entrega tareas',
              Icons.person_rounded,
            ),
            const SizedBox(width: 10),
            _rolCard(
              'maestro',
              'Maestro',
              'Crea clases y gestiona alumnos',
              Icons.person_outline_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Widget _rolCard(String value, String label, String desc, IconData icon) {
    final selected = rolSeleccionado == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => rolSeleccionado = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF0FF) : _cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _primary : _borderColor,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: selected ? _primary : const Color(0xFFF0F0F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: selected ? Colors.white : _textGray, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? _primary : _textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style:
                    const TextStyle(fontSize: 10, color: _textGray, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool? obscureState,
    VoidCallback? onToggleObscure,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureState ?? false,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _textGray, fontSize: 14),
            prefixIcon: Icon(icon, color: _textGray, size: 20),
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(
                      (obscureState ?? true)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _textGray,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            filled: true,
            fillColor: _cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDemoBanner(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(
                controller: correoController,
                label: 'Correo institucional',
                icon: Icons.alternate_email_rounded,
                hint: 'alumno@universidad.edu.mx',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                hint: '••••••••',
                obscure: true,
                obscureState: obscurePassword,
                onToggleObscure: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildPrimaryButton('Iniciar sesión', login),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRolSelector(),
          const SizedBox(height: 16),
          _buildField(
            controller: nombreController,
            label: 'Nombre completo',
            icon: Icons.person_outline_rounded,
            hint: 'Ej. Sofía Ramírez Torres',
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: correoController,
            label: 'Correo institucional',
            icon: Icons.alternate_email_rounded,
            hint: 'nombre@universidad.edu.mx',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: passwordController,
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            hint: 'Mínimo 8 caracteres',
            obscure: true,
            obscureState: obscurePassword,
            onToggleObscure: () =>
                setState(() => obscurePassword = !obscurePassword),
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: confirmarPasswordController,
            label: 'Confirmar contraseña',
            icon: Icons.lock_outline_rounded,
            hint: 'Repite tu contraseña',
            obscure: true,
            obscureState: obscureConfirm,
            onToggleObscure: () =>
                setState(() => obscureConfirm = !obscureConfirm),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton('Crear cuenta', registrar),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            // Animated form area
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    esRegistro ? _buildRegisterForm() : _buildLoginForm(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}