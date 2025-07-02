import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cuenta.dart';
import '../models/categoria.dart';
import '../models/transaccion.dart';
import '../models/datos_transaccion.dart';
import '../providers/transaction_provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/categoria_provider.dart';
import '../providers/cuenta_provider.dart';

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
    _fetchCategorias();
    _fetchCuentas();
    if (widget.datosGPT != null) {
      fillFormFromDatosTransaccion(widget.datosGPT!);
    }
  }

   /// Llena el formulario con los datos recibidos de GPT (excepto la cuenta)
  void fillFormFromDatosTransaccion(DatosTransaccion datos) {
    setState(() {
      _amountController.text = datos.monto;
      _noteController.text = datos.descripcion;
      _selectedType = datos.tipoTransaccion;
      _placeController.text = datos.lugar;
      
      // Buscar y seleccionar la categoría si GPT sugirió una
        final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
        final categoriaEncontrada = categoriaProvider.categorias.firstWhere(
          (cat) => cat.name.toLowerCase() == datos.categoria.toLowerCase(),
          orElse: () => categoriaProvider.categorias.first,
        );
        _selectedCategory = categoriaEncontrada;
      

      // Establecer la fecha si se proporcionó una
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
  final TextEditingController _placeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Cuenta? _selectedAccount;
  Categoria? _selectedCategory;
  String _selectedType = 'gasto';
  bool _loading = false;
  String? _transactionCurrency;
  final List<String> _currencyOptions = ['DOP', 'USD', 'EUR'];

  Color get emerald => const Color(0xFF00BFA5);
  Color get emerald2 => const Color.fromARGB(255, 29, 29, 29);
  Color get skyBlue => const Color.fromARGB(255, 28, 64, 80);
  Color get yellow => const Color(0xFFFFEB3B);
  Color get bgGray => const Color.fromARGB(255, 81, 81, 81);
  Color get darkText => const Color(0xFF212121);

  Future<List<Cuenta>> _fetchCuentas() async {
    final usuario =
        Provider.of<UsuarioProvider>(context, listen: false).usuario;
    if (usuario != null) {
      final cuentaProvider = Provider.of<CuentaProvider>(
        context,
        listen: false,
      );
      await cuentaProvider.cargarCuentas(usuario.id!);
      // Si hay una cuenta seleccionada, inicializamos la moneda de la transacción.
      if (_selectedAccount != null) {
        setState(() {
          _transactionCurrency = _selectedAccount!.moneda;
        });
      }
    }
    return [];
  }

  Future<void> _fetchCategorias() async {
    final usuario =
        Provider.of<UsuarioProvider>(context, listen: false).usuario;

    if (usuario != null) {
      final categoriaProvider = Provider.of<CategoriaProvider>(
        context,
        listen: false,
      );
      await categoriaProvider.cargarCategorias(usuario.id!);
    }
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
              primary: const Color.fromARGB(
                255,
                52,
                50,
                50,
              ), // color de acento (botón OK, selección)
              onPrimary: const Color.fromARGB(
                255,
                241,
                241,
                241,
              ), // texto sobre color de acento
              surface: Color.fromARGB(
                255,
                85,
                81,
                81,
              ), // fondo principal del calendario
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
    final usuario =
        Provider.of<UsuarioProvider>(context, listen: false).usuario;
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
      place: _placeController.text.trim().isEmpty ? null : _placeController.text.trim(),
      date: _selectedDate.toIso8601String(),
      amount: montoGasto,
      type: _selectedType,
      note: _noteController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
      moneda: _transactionCurrency!,
      conversion: _transactionCurrency != _selectedAccount!.moneda,
      montoConvertido: null, // El provider se encargará de esto
      tasaConversion: null, // El provider se encargará de esto
    );

    final result = await Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).agregarTransaccion(transaccion);

    setState(() => _loading = false);
    if (mounted) {
      String message =
          result
              ? 'Transacción guardada exitosamente. ¡Atención! Tu saldo quedó negativo.'
              : 'Transacción guardada exitosamente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result ? Colors.orange : null,
        ),
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
                Consumer<CuentaProvider>(
                  builder: (context, cuentaProvider, _) {
                    if (cuentaProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final cuentas = cuentaProvider.cuentas;
                    Cuenta? selectedAccount;
                    if (_selectedAccount != null && cuentas.isNotEmpty) {
                      selectedAccount = cuentas.firstWhere(
                        (c) => c.id == _selectedAccount!.id,
                        orElse: () => cuentas.first,
                      );
                    }
                    return DropdownButtonFormField<Cuenta>(
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      dropdownColor: Colors.grey[800],
                      value: selectedAccount,
                      items:
                          cuentas
                              .map(
                                (cuenta) => DropdownMenuItem(
                                  value: cuenta,
                                  child: Text(
                                    cuenta.name,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (cuenta) => setState(() {
                            _selectedAccount = cuenta;
                            _transactionCurrency =
                                cuenta
                                    ?.moneda; // Actualiza la moneda por defecto para la transaccion
                          }),
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
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      validator:
                          (c) =>
                              c == null ? 'Seleccione una cuenta' : null,
                    );
                  },
                ),
                const SizedBox(height: 18),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  maxLines: 1,
                  controller: _placeController,
                  decoration: InputDecoration(
                    labelText: 'Lugar',
                    prefixIcon: const Icon(
                      Icons.location_on_rounded,
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
                const SizedBox(height: 18),
                Consumer<CategoriaProvider>(
                  builder: (context, categoriaProvider, _) {
                    if (categoriaProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final categorias = categoriaProvider.categorias;
                    Categoria? selectedCategory;
                    if (_selectedCategory != null && categorias.isNotEmpty) {
                      selectedCategory = categorias.firstWhere(
                        (cat) => cat.id == _selectedCategory!.id,
                        orElse: () => categorias.first,
                      );
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
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(color: Colors.white),
                                  ),
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
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        labelStyle: const TextStyle(color: Colors.white),
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
                const SizedBox(height: 18),
                // Selector de Moneda de la Transacción
                DropdownButtonFormField<String>(
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  dropdownColor: Colors.grey[800],
                  value: _transactionCurrency,
                  items:
                      _currencyOptions
                          .map(
                            (moneda) => DropdownMenuItem(
                              value: moneda,
                              child: Text(
                                moneda,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (moneda) => setState(() => _transactionCurrency = moneda),
                  decoration: InputDecoration(
                    labelText: 'Moneda de la transacción',
                    prefixIcon: const Icon(Icons.money, color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  validator: (m) => m == null ? 'Seleccione una moneda' : null,
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
