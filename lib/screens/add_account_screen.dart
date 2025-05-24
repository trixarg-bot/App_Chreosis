import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chreosis_app/providers/cuenta_provider.dart';
import '../providers/usuario_provider.dart';
import 'package:chreosis_app/widgets/lista_iconos.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedType;
  IconData _selectedIcon = Icons.account_balance_wallet_rounded;

  // Valores dinámicos para la tarjeta
  String get name => _nameController.text;
  String get amount => _amountController.text;
  String get type => _selectedType ?? '';

  // Lista para la selección de iconos
  Future<void> seleccionarIcono(BuildContext context) async {
    final iconoSeleccionado = await showDialog<IconData>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Selecciona un icono'),
          children: listaIconosPersonalizados.map((icono) {
            return ListTile(
              leading: Icon(icono['icon'], size: 32),
              title: Text(icono['label']),
              onTap: () => Navigator.pop(ctx, icono['icon']),
            );
          }).toList(),
        );
      },
    );
    if (iconoSeleccionado != null) {
      setState(() => _selectedIcon = iconoSeleccionado);
    }
  }


  // Opciones de tipo de cuenta
  final List<String> _typeOptions = [
    'Efectivo',
    'Banco',
    'Tarjeta',
    'Otro',
  ];

  void _clearForm() {
    _nameController.clear();
    _amountController.clear();
    setState(() {
      _selectedType = '';
      _selectedIcon = Icons.account_balance_wallet_rounded;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //obtener el provider cuenta
    final cuentaProvider = Provider.of<CuentaProvider>(context);
    //obtener el provider usuario
    final userProvider = Provider.of<UsuarioProvider>(context, listen: false);


    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: Text('Nueva cuenta', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta dinámica
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 29, 29, 29),Color.fromARGB(255, 28, 64, 80)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de icono
                      GestureDetector(
                        onTap: () => seleccionarIcono(context),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color.fromARGB(255, 37, 38, 39),
                          child: Icon(_selectedIcon, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Nombre' : name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              amount.isEmpty ? 'monto inicial' : '\$$amount',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 153, 147, 147),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type.isEmpty ? 'tipo' : type,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Formulario
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nombre de la cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                  const SizedBox(height: 4),
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 134, 133, 133),
                      hintText: 'Ingrese el nombre...',
                      hintStyle: TextStyle(color: const Color.fromARGB(255, 66, 66, 66), fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Ingrese el nombre' : null,
                  ),
                  const SizedBox(height: 18),
                  const Text('Monto inicial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                  const SizedBox(height: 4),
                  TextFormField(
                    style: const TextStyle(color: Colors.white),
                    controller: _amountController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color.fromARGB(255, 134, 133, 133),
                      hintText: 'Ingrese el monto...',
                      hintStyle: TextStyle(color: const Color.fromARGB(255, 66, 66, 66), fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Ingrese el monto' : null,
                  ),
                  const SizedBox(height: 18),
                  const Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                  const SizedBox(height: 4),
                   DropdownButtonFormField<String>(
                    dropdownColor: Colors.grey[800],
                    value: _selectedType,
                    items: _typeOptions.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type, style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                    decoration: InputDecoration(
                      hintText: 'Seleccione un tipo...',
                      hintStyle: TextStyle(fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: Color.fromARGB(255, 134, 133, 133),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Seleccione un tipo' : null,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearForm,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color.fromARGB(255, 55, 54, 54),
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Limpiar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final usuario = userProvider.usuario!;
                              
                              await cuentaProvider.agregarCuenta(
                                userId: usuario.id!,
                                name: _nameController.text.trim(),
                                type: _selectedType!,
                                amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cuenta guardada correctamente')),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color.fromARGB(255, 55, 54, 54),
                            side: const BorderSide(color: Colors.white, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Guardar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
