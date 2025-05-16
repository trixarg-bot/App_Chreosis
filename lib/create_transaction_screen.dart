import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'db/database_helper.dart';
import 'models/cuenta.dart';
import 'models/categoria.dart';
import 'models/transaccion.dart';
import 'models/datos_transaccion.dart';
import 'user_provider.dart';

class CreateTransactionScreen extends StatefulWidget {
  final DatosTransaccion? datosGPT;
  const CreateTransactionScreen({Key? key, this.datosGPT}) : super(key: key);

  @override
  State<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.datosGPT != null) {
      fillFormFromDatosTransaccion(widget.datosGPT!);
    }
  }
  // ...
  /// Llena el formulario con los datos recibidos de GPT (excepto la cuenta)
  void fillFormFromDatosTransaccion(DatosTransaccion datos) {
    setState(() {
      _amountController.text = datos.monto;
      _noteController.text = datos.descripcion;
      _selectedType = datos.tipoTransaccion;
      // La categoría se buscará por nombre cuando estén cargadas
      // La cuenta NO se llena aquí
      if (datos.fecha.isNotEmpty) {
        try {
          final partes = datos.fecha.split('-');
          if (partes.length == 3) {
            _selectedDate = DateTime(
              int.parse(partes[2]),
              int.parse(partes[1]),
              int.parse(partes[0]),
            );
          }
        } catch (_) {}
      }
    });
  }
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Cuenta? _selectedAccount;
  Categoria? _selectedCategory;
  String _selectedType = 'gasto';
  bool _loading = false;

  Color get emerald => const Color(0xFF00BFA5);
  Color get emerald2 => const Color.fromARGB(255, 29, 29, 29);
  Color get skyBlue => const Color.fromARGB(255, 28, 64, 80);
  Color get yellow => const Color(0xFFFFEB3B);
  Color get bgGray => const Color.fromARGB(255, 81, 81, 81);
  Color get darkText => const Color(0xFF212121);

  Future<List<Cuenta>> _fetchCuentas(BuildContext context) async {
    final usuario = Provider.of<UserProvider>(context, listen: false).usuario;
    if (usuario == null) return [];
    return await DatabaseHelper.instance.getCuentasByUser(usuario.id!);
  }

  Future<List<Categoria>> _fetchCategorias(BuildContext context) async {
    final usuario = Provider.of<UserProvider>(context, listen: false).usuario;
    if (usuario == null) return [];
    return await DatabaseHelper.instance.getCategorias(userId: usuario.id!);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 52, 50, 50), // color de acento (botón OK, selección)
              onPrimary: const Color.fromARGB(255, 241, 241, 241), // texto sobre color de acento
              surface: Color.fromARGB(255, 85, 81, 81), // fondo principal del calendario
              onSurface: Colors.white, // texto principal
              background: Colors.white, // fondo general
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, // color de los botones Cancel/OK
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final usuario = Provider.of<UserProvider>(context, listen: false).usuario;
    if (usuario == null ||
        _selectedAccount == null ||
        _selectedCategory == null)
      return;
    setState(() => _loading = true);
    final montoGasto = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final transaccion = Transaccion(
      userId: usuario.id!,
      accountId: _selectedAccount!.id!,
      categoryId: _selectedCategory!.id!,
      date: _selectedDate.toIso8601String(),
      amount: montoGasto,
      type: _selectedType,
      note: _noteController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    // Validar fondos suficientes antes de guardar la transacción
    final cuenta = await DatabaseHelper.instance.getCuentaById(
      _selectedAccount!.id!,
    );
    if (_selectedType == 'gasto' && cuenta != null && montoGasto > cuenta.amount) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fondos insuficientes en la cuenta seleccionada.')),
      );
      return;
    }

    await DatabaseHelper.instance.insertTransaccion(transaccion);

    // ACTUALIZAR MONTO DE LA CUENTA
    if (cuenta != null) {
      double nuevoMonto = cuenta.amount;
      if (_selectedType == 'gasto') {
        nuevoMonto -= transaccion.amount;
      } else {
        nuevoMonto += transaccion.amount;
      }
      final cuentaActualizada = Cuenta(
        id: cuenta.id,
        userId: cuenta.userId,
        name: cuenta.name,
        type: cuenta.type,
        amount: nuevoMonto,
      );
      await DatabaseHelper.instance.updateCuenta(cuentaActualizada);
    }

    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transacción guardada exitosamente')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Nueva Transacción',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [emerald2, skyBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedType == 'gasto'
                            ? 'Registrar Gasto'
                            : 'Registrar Ingreso',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text(
                              'Gasto',
                              style: TextStyle(color: Colors.white),
                            ),
                            selected: _selectedType == 'gasto',
                            onSelected:
                                (v) => setState(() => _selectedType = 'gasto'),
                            selectedColor: Colors.red,
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color:
                                  _selectedType == 'gasto' ? darkText : emerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text(
                              'Ingreso',
                              style: TextStyle(color: Colors.white),
                            ),
                            selected: _selectedType == 'ingreso',
                            onSelected:
                                (v) =>
                                    setState(() => _selectedType = 'ingreso'),
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color:
                                  _selectedType == 'ingreso'
                                      ? Colors.white
                                      : emerald,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      color: Colors.white,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  validator:
                      (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Ingrese el monto'
                              : null,
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<Cuenta>>(
                  future: _fetchCuentas(context),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final cuentas = snapshot.data!;
                    Cuenta? selectedAccount;
                    if (_selectedAccount != null && cuentas.isNotEmpty) {
                      selectedAccount = cuentas.firstWhere(
                        (c) => c.id == _selectedAccount!.id,
                        orElse: () => cuentas.first,
                      );
                    } else {
                      selectedAccount = null;
                    }
                    return DropdownButtonFormField<Cuenta>(
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      dropdownColor: Colors.grey[800],
                      value: selectedAccount,
                      items:
                          cuentas
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                      onChanged: (c) => setState(() => _selectedAccount = c),
                      decoration: InputDecoration(
                        labelText: 'Cuenta',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator:
                          (c) => c == null ? 'Seleccione una cuenta' : null,
                    );
                  },
                ),
                const SizedBox(height: 18),
                FutureBuilder<List<Categoria>>(
                  future: _fetchCategorias(context),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final categorias = snapshot.data!;
                    Categoria? selectedCategory;
                    if (_selectedCategory != null && categorias.isNotEmpty) {
                      selectedCategory = categorias.firstWhere(
                        (cat) => cat.id == _selectedCategory!.id,
                        orElse: () => categorias.first,
                      );
                    } else {
                      selectedCategory = null;
                    }
                    return DropdownButtonFormField<Categoria>(
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      dropdownColor: Colors.grey[800],
                      value: selectedCategory,
                      items:
                          categorias
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.name),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (cat) => setState(() => _selectedCategory = cat),
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: const Icon(
                          Icons.category,
                          color: Colors.white,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator:
                          (cat) =>
                              cat == null ? 'Seleccione una categoría' : null,
                    );
                  },
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Nota (opcional)',
                    prefixIcon: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 55, 54, 54),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: OutlinedButton(
                          onPressed:
                              _loading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 55, 54, 54),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: OutlinedButton(
                          onPressed: _loading ? null : _saveTransaction,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent, // ¡IMPORTANTE!
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child:
                              _loading
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text(
                                    'Guardar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 