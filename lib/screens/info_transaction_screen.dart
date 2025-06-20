import 'package:flutter/material.dart';
import '../models/transaccion.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cuenta_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/cuenta.dart';
import '../models/categoria.dart';
import '../providers/transaction_provider.dart';
import '../providers/usuario_provider.dart';

class InfoTransactionScreen extends StatefulWidget {
  final Transaccion transaccion;
  const InfoTransactionScreen({super.key, required this.transaccion});

  @override
  State<InfoTransactionScreen> createState() => _InfoTransactionScreenState();
}

class _InfoTransactionScreenState extends State<InfoTransactionScreen> {
  bool isEditing = false;
  late int selectedAccountId;
  late int selectedCategoryId;
  late String place;
  late String note;
  late double amount;
  late String type;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedAccountId = widget.transaccion.accountId;
    selectedCategoryId = widget.transaccion.categoryId;
    place = widget.transaccion.place ?? '';
    note = widget.transaccion.note ?? '';
    amount = widget.transaccion.amount;
    type = widget.transaccion.type ?? 'gasto';
    selectedDate =
        widget.transaccion.date != null && widget.transaccion.date!.isNotEmpty
            ? DateTime.tryParse(widget.transaccion.date!) ?? DateTime.now()
            : DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00', 'en_US');
    final monto = numberFormat.format(amount);
    final fecha =
        '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    final cuentas = Provider.of<CuentaProvider>(context).cuentas;
    final categorias = Provider.of<CategoriaProvider>(context).categorias;
    final cuenta =
        cuentas
            .firstWhere(
              (c) => c.id == selectedAccountId,
              orElse:
                  () => Cuenta(
                    id: -1,
                    userId: 0,
                    name: selectedAccountId.toString(),
                    type: '',
                    amount: 0,
                  ),
            )
            .name;
    final categoria =
        categorias
            .firstWhere(
              (cat) => cat.id == selectedCategoryId,
              orElse:
                  () => Categoria(
                    id: -1,
                    userId: 0,
                    name: selectedCategoryId.toString(),
                    type: '',
                    iconCode: 0,
                  ),
            )
            .name;

    return Scaffold(
      backgroundColor: const Color(0xFF282C35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF282C35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Información de Transferencia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Gasto Realizado y Monto
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3F4C),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        type == 'gasto' ? 'Gasto Realizado' : 'Ingreso',
                        style: TextStyle(
                          color:
                              type == 'gasto'
                                  ? Color(0xFFEB5757)
                                  : Color(0xFF00BFA5),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (type == 'gasto'
                                  ? Color(0xFFEB5757)
                                  : Color(0xFF00BFA5))
                              .withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          type == 'gasto'
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color:
                              type == 'gasto'
                                  ? Color(0xFFEB5757)
                                  : Color(0xFF00BFA5),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Monto Total',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  isEditing
                      ? TextFormField(
                        initialValue: amount.toString(),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixText: '\$',
                        ),
                        onChanged: (v) {
                          setState(() {
                            amount = double.tryParse(v) ?? 0.0;
                          });
                        },
                      )
                      : Text(
                        '\$$monto',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Info editable
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child:
                      isEditing
                          ? DropdownButtonFormField<int>(
                            value: selectedAccountId,
                            dropdownColor: const Color(0xFF3A3F4C),
                            decoration: const InputDecoration(
                              labelText: 'Cuenta',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            items:
                                cuentas
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(
                                          c.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedAccountId = v!;
                              });
                            },
                          )
                          : _buildInfoCard(
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: const Color(0xFF4FC3F7),
                            label: 'Cuenta',
                            value: cuenta,
                          ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child:
                      isEditing
                          ? TextFormField(
                            initialValue: place,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Lugar',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              setState(() {
                                place = v;
                              });
                            },
                          )
                          : _buildInfoCard(
                            icon: Icons.location_on,
                            iconColor: const Color(0xFF9B51E0),
                            label: 'Lugar',
                            value: place,
                          ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child:
                      isEditing
                          ? DropdownButtonFormField<int>(
                            value: selectedCategoryId,
                            dropdownColor: const Color(0xFF3A3F4C),
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            items:
                                categorias
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat.id,
                                        child: Text(
                                          cat.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedCategoryId = v!;
                              });
                            },
                          )
                          : _buildInfoCard(
                            icon: Icons.category,
                            iconColor: const Color(0xFF27AE60),
                            label: 'Categoría',
                            value: categoria,
                          ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child:
                      isEditing
                          ? InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                fecha,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          : _buildInfoCard(
                            icon: Icons.calendar_today,
                            iconColor: const Color(0xFFF2C94C),
                            label: 'Fecha',
                            value: fecha,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Sección de Nota
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3F4C),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.notes,
                    color: Colors.white.withOpacity(0.7),
                    size: 24,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nota',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 5),
                        isEditing
                            ? TextFormField(
                              initialValue: note,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  note = v;
                                });
                              },
                            )
                            : Text(
                              note,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!isEditing) {
                        setState(() {
                          isEditing = true;
                        });
                      } else {
                        // Guardar cambios
                        final usuario =
                            Provider.of<UsuarioProvider>(
                              context,
                              listen: false,
                            ).usuario;
                        if (usuario == null) return;
                        final nuevaTransaccion = Transaccion(
                          id: widget.transaccion.id,
                          userId: usuario.id!,
                          accountId: selectedAccountId,
                          categoryId: selectedCategoryId,
                          place: place,
                          date: selectedDate.toIso8601String(),
                          amount: amount,
                          type: type,
                          note: note,
                          createdAt: widget.transaccion.createdAt,
                        );
                        await Provider.of<TransactionProvider>(
                          context,
                          listen: false,
                        ).updateTransaccion(nuevaTransaccion);
                        setState(() {
                          isEditing = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Transacción actualizada exitosamente',
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A3F4C),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Guardar' : 'Editar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: const Text(
                              '¿Estás seguro de que quieres eliminar esta transacción?',
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmar == true) {
                        if (!mounted) return;
                        final transactionProvider =
                            Provider.of<TransactionProvider>(
                              context,
                              listen: false,
                            );
                        final cuentaProvider = Provider.of<CuentaProvider>(
                          context,
                          listen: false,
                        );
                        await transactionProvider.deleteTransaccion(
                          widget.transaccion.id!,
                          widget.transaccion.userId,
                        );
                        await cuentaProvider.cargarCuentas(
                          widget.transaccion.userId,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transacción eliminada'),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEB5757),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3F4C),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }
}
