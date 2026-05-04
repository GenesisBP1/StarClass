import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  final auth = AuthService();
void login() async {
  try {
    print("Correo: ${correoController.text}");
    print("Password: ${passwordController.text}");

    final res = await auth.login(
      correoController.text.trim(),
      passwordController.text.trim(),
    );

    print(res);

    final user = res['user'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('correo', user['correo']);
    await prefs.setString('nombre', user['nombre']);
    await prefs.setString('rol', user['rol']);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login exitoso")),
    );

    if (user['rol'] == 'maestro') {
      Navigator.pushReplacementNamed(context, '/maestro');
    } else {
      Navigator.pushReplacementNamed(context, '/alumno');
    }

  } catch (e) {
    print("ERROR LOGIN: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Credenciales incorrectas")),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("StarClass Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: correoController,
              decoration: const InputDecoration(labelText: "Correo"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: const Text("Iniciar sesión"),
            )
          ],
        ),
      ),
    );
  }
}