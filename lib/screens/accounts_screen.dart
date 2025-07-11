//TODO: HACER QUE EL NOMBRE DE LA CUENTA NO ACEPTE NUMEROS.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_account_screen.dart';
import '../providers/usuario_provider.dart';
import '../providers/cuenta_provider.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async { 
    final usuario = Provider.of<UsuarioProvider>(context, listen: false).usuario;
    if (usuario != null) {
      final cuentaProvider = Provider.of<CuentaProvider>(context, listen: false);
      await cuentaProvider.cargarCuentas(usuario.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Paleta de colores
    const emerald = Color.fromARGB(255, 29, 29, 29);
    const skyBlue = Color.fromARGB(255, 28, 64, 80);

    // const bgGray = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Colors.grey[850],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAccountScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Cuenta', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 44, 43, 43),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final usuario = Provider.of<UsuarioProvider>(context).usuario;
            if (usuario == null) {
              return const Center(
                child: Text('No hay usuario autenticado'),
              );
            }

            return Column(
              children: [
                // Header visual
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [emerald, skyBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Cuentas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Comic Sans MS',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Saldo Total',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Consumer<CuentaProvider>(
                        builder: (context, cuentaProvider, _) {
                          if (cuentaProvider.isLoading) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                height: 18, 
                                width: 18, 
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70
                                )
                              ),
                            );
                          }
                          
                          final saldo = cuentaProvider.cuentas.fold<double>(
                            0.0,
                            (total, cuenta) => total + cuenta.amount
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 2),
                            child: Text(
                              '\$${saldo.toStringAsFixed(2)}',
                              style: TextStyle(
                                color:
                                    saldo < 0
                                        ? const Color(
                                          0xFFEB5757,
                                        ) // Rojo para saldos negativos
                                        : Colors
                                            .white, // Blanco para saldos positivos
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Lista de cuentas
                Expanded(
                  child: Consumer<CuentaProvider>(
                    builder: (context, cuentaProvider, _) {
                      if (cuentaProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final cuentas = cuentaProvider.cuentas;
                      if (cuentas.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay cuentas registradas',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        itemCount: cuentas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final cuenta = cuentas[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color.fromARGB(255, 89, 88, 88),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                cuenta.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '\$${cuenta.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        cuenta.amount < 0
                                            ? const Color(
                                              0xFFEB5757,
                                            ) // Rojo para saldos negativos
                                            : const Color.fromARGB(
                                              255,
                                              169,
                                              167,
                                              167,
                                            ), // Color original para saldos positivos
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color.fromARGB(255, 169, 167, 167),
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      // TODO: Acción de editar
                                    },
                                    splashRadius: 18,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.white.withAlpha((0.7 * 255).toInt()),
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('¿Eliminar cuenta?'),
                                          content: const Text('Esta acción eliminará la cuenta seleccionada. ¿Seguro que deseas continuar?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(true),
                                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await cuentaProvider.eliminarCuenta(cuenta.id!);
                                        if (mounted) {
                                          setState(() {});
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Cuenta eliminada.')),
                                          );
                                        }
                                      }
                                    },
                                    splashRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
