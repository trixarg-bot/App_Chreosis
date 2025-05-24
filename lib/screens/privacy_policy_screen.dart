import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF18191A), // Fondo oscuro
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
        backgroundColor: const Color(0xFF23272A),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        color: const Color(0xFF18191A),
        child: SingleChildScrollView(
          child: Card(
            elevation: 2,
            color: const Color(0xFF23272A), // Card oscuro
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Política de Privacidad – Chreosis',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Última actualización: 12-05-2025',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('1. Información que recopilamos', theme),
                  _sectionBody('Dependiendo del uso que hagas de la app, podemos recopilar:'),
                  _sectionBullet('Datos personales mínimos: nombre, correo electrónico, teléfono (si decides registrarte o asociar datos).'),
                  _sectionBullet('Información financiera que ingresas manualmente: como categorías de gasto, transacciones, cuentas, montos, fechas y notas relacionadas.'),
                  _sectionBullet('Datos técnicos anónimos: como el tipo de dispositivo, sistema operativo y errores técnicos, utilizados para mejorar la estabilidad y experiencia de la app.'),
                  const SizedBox(height: 18),
                  _sectionTitle('2. Uso de la información', theme),
                  _sectionBody('La información que gestionas en Chreosis es utilizada únicamente para:'),
                  _sectionBullet('Brindarte una experiencia personalizada.'),
                  _sectionBullet('Mostrarte reportes y estadísticas sobre tus finanzas.'),
                  _sectionBullet('Guardar tus configuraciones, preferencias y categorías personalizadas.'),
                  _sectionBullet('Mejorar la funcionalidad y el rendimiento de la app.'),
                  _sectionBody('Chreosis no vende, alquila ni comparte tu información personal o financiera con terceros.'),
                  const SizedBox(height: 18),
                  _sectionTitle('3. Almacenamiento y seguridad', theme),
                  _sectionBody('Tus datos se almacenan de manera local en tu dispositivo, o de forma cifrada si habilitas sincronización opcional con servicios en la nube (si se ofrece en futuras versiones).'),
                  _sectionBody('Usamos estándares de seguridad robustos para proteger tu información, incluyendo cifrado de datos, acceso controlado y buenas prácticas de desarrollo seguro.'),
                  const SizedBox(height: 18),
                  _sectionTitle('4. Control del usuario', theme),
                  _sectionBullet('Puedes modificar, actualizar o eliminar tus datos en cualquier momento desde la aplicación.'),
                  _sectionBullet('Puedes desinstalar la app y, con ello, eliminar completamente tus datos del dispositivo.'),
                  _sectionBody('Próximamente habilitaremos opciones para exportar tu información financiera en formatos compatibles (ej. CSV o PDF).'),
                  const SizedBox(height: 18),
                  _sectionTitle('5. Cookies y rastreo', theme),
                  _sectionBody('Chreosis no utiliza cookies ni tecnologías de rastreo dentro de la app.'),
                  _sectionBody('No realizamos seguimiento publicitario ni vendemos hábitos de consumo a terceros.'),
                  const SizedBox(height: 18),
                  _sectionTitle('6. Cambios en esta política', theme),
                  _sectionBody('Nos reservamos el derecho de modificar esta política para reflejar mejoras o requisitos legales. Notificaremos cualquier cambio importante dentro de la app o mediante otros canales oficiales.'),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23272A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.teal[200],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70),
      ),
    );
  }

  Widget _sectionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 17, color: Colors.tealAccent)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
