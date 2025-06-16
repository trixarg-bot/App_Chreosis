import 'package:flutter/material.dart';
import 'register_user_screen.dart';
// import 'package:rive/rive.dart' as rive ;
import 'package:chreosis_app/db/database_helper.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      final usuario = await DatabaseHelper.instance.getUsuarioById(userId);
      if (usuario != null && mounted) {
        Provider.of<UsuarioProvider>(context, listen: false).setUsuario(usuario);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _login() async {
    final user = _userController.text.trim();
    final pass = _passController.text.trim();
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa usuario y contraseña')),
      );
      return;
    }
    setState(() => _loading = true);
    final usuario = await DatabaseHelper.instance.getUsuarioByName(user);
    setState(() => _loading = false);
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no encontrado')),
      );
      return;
    }
    if (usuario.password != pass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña incorrecta')),
      );
      return;
    }
    // Guardar sesión
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', usuario.id!);
    // Guardar usuario en Provider
    if (mounted) {
      Provider.of<UsuarioProvider>(context, listen: false).setUsuario(usuario);
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 29, 29, 29),
              Color.fromARGB(255, 28, 64, 80),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  color: Colors.grey[850],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: const Icon(Icons.person, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bienvenido',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 232, 235, 235),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 192, 194, 194)),
                        ),
                        const SizedBox(height: 32),
                        // Usuario
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: const [
                              Text('Usuario', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 192, 194, 194))),
                              SizedBox(width: 8),
                              Icon(Icons.person, size: 20, color: Color.fromARGB(255, 192, 194, 194)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _userController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F8E9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Color(0xFF18D1B7)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Color(0xFF18D1B7), width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Contraseña
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: const [
                              Text('Contraseña', style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 192, 194, 194))),
                              SizedBox(width: 8),
                              Icon(Icons.lock, size: 20, color: Color.fromARGB(255, 192, 194, 194)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _passController,
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0xFFF1F8E9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Color(0xFF18D1B7)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Color(0xFF18D1B7), width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Botón Iniciar Sesión
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.login, color: Colors.white),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 67, 93, 89),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 10,
                            ),
                            onPressed: _loading ? null : _login,
                            label: const Text(
                              'Iniciar Sesión',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Botón Crear Cuenta
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.person_add, color: Color.fromARGB(255, 255, 255, 255)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color.fromARGB(255, 95, 159, 150), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              foregroundColor: Color.fromARGB(255, 255, 255, 255),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegisterUserScreen()),
                              );
                            },
                            label: const Text(
                              'Crear Cuenta',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Política de privacidad
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/privacy_policy'),
                              child: Text('Política de Privacidad', style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 255, 255, 255))),
                            ),
                            SizedBox(width: 0),
                            Icon(Icons.info_outline, size: 22, color: const Color.fromARGB(255, 255, 255, 255)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // Animación decorativa
                // SizedBox(
                //   height: 100,
                //   child: rive.RiveAnimation.asset(
                //     'assets/Logo.riv',
                //     fit: BoxFit.contain,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }
}

