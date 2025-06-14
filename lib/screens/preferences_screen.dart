import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chreosis_app/services/firebase_service.dart';
import 'package:chreosis_app/db/database_helper.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      backgroundColor: Colors.grey[850],
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          const SizedBox(height: 10),
          _SectionTitle('Funcionalidad'),
          _SettingsTile(
            icon: Icons.category_rounded,
            title: 'Agregar / Gestionar categorías',
            titleColor: Colors.white,
            subtitle: 'Personaliza tus categorías',
            onTap: () => Navigator.pushNamed(context, '/add_category'),
          ),
          _SettingsTile(
            icon: Icons.email_rounded,
            title: 'Conectar correo',
            titleColor: Colors.white,
            subtitle: 'Sincroniza tus notificaciones de consumo',
            onTap: () => Navigator.pushNamed(context, '/email_setup'),
          ),
          _SectionTitle('Personalización'),
          _SettingsTile(
            icon: Icons.attach_money_rounded,
            title: 'Personalizar moneda',
            titleColor: Colors.white,
            subtitle: 'Pesos, Dólares, Euros...'
          ),
          _SettingsTile(
            icon: Icons.flash_on_rounded,
            title: 'Configurar inicio rápido',
            titleColor: Colors.white,
            subtitle: 'Elige pantalla de inicio'
          ),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            title: 'Modo oscuro',
            titleColor: Colors.white,
            subtitle: 'Activa/desactiva modo oscuro',
            trailing: Switch(value: false, onChanged: null),
          ),
          _SectionTitle('Recordatorios y notificaciones'),
          _SettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Recordatorio de gastos diarios',
            titleColor: Colors.white,
            subtitle: 'Recibe notificaciones diarias',
            trailing: Switch(value: false, onChanged: null),
          ),
          _SectionTitle('General'),
          _SettingsTile(
            icon: Icons.language_rounded,
            titleColor: Colors.white,
            title: 'Idioma de la app',
            subtitle: 'Español, Inglés'
          ),
          _SettingsTile(
            icon: Icons.backup_rounded,
            title: 'Copia de seguridad (Backup Manual)',
            titleColor: Colors.white,
            subtitle: 'Exporta tus datos locales'
          ),
          _SettingsTile(
            icon: Icons.restore,
            title: 'Restablecer categorías',
            titleColor: Colors.white,
            subtitle: 'Vuelve a los valores predeterminados'
          ),
          _SettingsTile(
            icon: Icons.person,
            title: 'Cambiar nombre y correo',
            titleColor: Colors.white,
            subtitle: 'Edita tu perfil'
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Cerrar sesión',
            subtitle: 'Resetear cuenta o sesión',
            titleColor: Colors.red,
            onTap: () async {
              // Limpiar sesión en Provider
              final userProvider = Provider.of<UsuarioProvider>(context, listen: false);
              userProvider.logout();
              // Limpiar sesión en SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_id');
              // Navegar a LoginScreen y limpiar el stack de navegación
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
          _buildSection(
            'Conectar Correo',
            [
              _buildEmailConnectButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildEmailConnectButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () async {
          try {
            await FirebaseService.connectGmailAndRegisterDevice();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Por favor, completa la autenticación en el navegador'),
                duration: Duration(seconds: 5),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.grey[800],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.email, color: Colors.white),
            SizedBox(width: 8),
            Text('Conectar Gmail', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 8, left: 4),
      child: Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color.fromARGB(255, 30, 30, 44),Color.fromARGB(255, 0, 0, 0)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(9),
                child: Icon(icon, color: const Color.fromARGB(255, 255, 255, 255), size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: titleColor ?? Colors.black)),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onTap != null && trailing == null)
                const Icon(Icons.arrow_forward_ios_rounded, size: 17, color: Color(0xFFB0B0B0)),
            ],
          ),
        ),
      ),
    );
  }
}
