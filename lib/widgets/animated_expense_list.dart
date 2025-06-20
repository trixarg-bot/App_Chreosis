import 'package:flutter/material.dart';
import 'package:chreosis_app/widgets/expense_card.dart';
import 'package:chreosis_app/models/transaccion.dart';
import 'package:chreosis_app/models/categoria.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import 'package:provider/provider.dart';
import '../screens/info_transaction_screen.dart';

class AnimatedExpenseListState extends State<AnimatedExpenseList> {
  double _opacity = 0.0;


  String _formatDate(DateTime date) {
  final meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${date.day} de ${meses[date.month - 1]} ${date.year}';
}



  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
    
  }

  @override
  Widget build(BuildContext context) {
    // Excluye las 3 más recientes
    final items =
        widget.allTransactions.length > 3
            ? widget.allTransactions.sublist(3)
            : <Transaccion>[];
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No hay más transacciones registradas.', style: TextStyle(color: Colors.white)),
      );
    }

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final t = items[i];
          final categoria = widget.mapaCategorias[t.categoryId];
          final nombreCategoria = categoria?.name ?? 'Sin categoría';
          final isIngreso = t.type == 'ingreso';
          final numberFormat = NumberFormat('#,##0.00', 'en_US');
          final formattedAmount = numberFormat.format(t.amount);
          final amountStr = '${isIngreso ? '+ ' : '- '}\$$formattedAmount';
          final amountColor = isIngreso ? Color(0xFF00BFA5) : Color(0xFFD32F2F);
          final iconCode = categoria?.iconCode ?? Icons.category.codePoint;
          final icon = IconData(iconCode, fontFamily: 'MaterialIcons');
          final formattedDate = t.date != null ? _formatDate(DateTime.parse(t.date!)) : '';
          return Dismissible(
            key: ValueKey(t.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 32),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: const Text('¿Borrar transacción?'),
                      content: const Text(
                        'Esta acción revertirá el saldo de la cuenta asociada.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Borrar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
              );
            },
            onDismissed: (direction) async {
              try {
                await Provider.of<TransactionProvider>(context, listen: false)
                    .deleteTransaccion(t.id!, t.userId);
                if (widget.onTransaccionEliminada != null) {
                  widget.onTransaccionEliminada!();
                }
              } catch (e) {
                print('Error al eliminar: $e');
              }
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InfoTransactionScreen(transaccion: t),
                  ),
                );
              },
              child: ExpenseCardBase(
                icon: icon,
                category: nombreCategoria,
                amount: amountStr,
                date: formattedDate,
                amountColor: amountColor,
              ),
            ),
          );
        },
      ),
    );
  }
}


class AnimatedExpenseList extends StatefulWidget {
  final List<Transaccion> allTransactions;
  final Map<int, Categoria> mapaCategorias;
  final VoidCallback? onTransaccionEliminada;
  const AnimatedExpenseList({
    required this.allTransactions,
    required this.mapaCategorias,
    this.onTransaccionEliminada,
  });

  @override
  State<AnimatedExpenseList> createState() => AnimatedExpenseListState();
}