// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'accounts_screen.dart';
import 'create_transaction_screen.dart';
import 'package:provider/provider.dart';
import 'db/database_helper.dart';
import 'user_provider.dart';
import 'models/transaccion.dart';
import 'page_reportes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _UserHomeData {
  final String balance;
  final List<_ExpenseCardData> featuredExpenses;
  final List<Transaccion> allTransactions;
  final Map<int, String> categoriaNombres;
  final Map<int, int> categoriaIconos;
  _UserHomeData({
    required this.balance,
    required this.featuredExpenses,
    required this.allTransactions,
    required this.categoriaNombres,
    required this.categoriaIconos,
  });
}

class _ExpenseCardData {
  final IconData icon;
  final String category;
  final String amount;
  final String date;
  final Color color;
  _ExpenseCardData({
    required this.icon,
    required this.category,
    required this.amount,
    required this.date,
    required this.color,
  });
}

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

class _HomeScreenState extends State<HomeScreen> { 
  final numberFormat = NumberFormat('#,##0.00', 'en_US');
  final SpeechToText speechToText = SpeechToText();
  bool isSpeechEnabled = false; // Indica si el reconocimiento de voz está habilitado
  bool isUserStopped = false; // Indica si el usuario ha detenido la escucha
  bool isListening = false; // Indica si el reconocimiento de voz está en curso
  String lastWords = ''; // Últimas palabras reconocidas
  final ValueNotifier<String> lastWordsNotifier = ValueNotifier(''); // Notificador para las últimas palabras reconocidas
  String fullTranscription = ''; // Transcripción  completa de lo que ha dicho el usuario

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  //Esto sucede una vez al iniciar la app
  void initSpeech() async {
    isListening = await speechToText.initialize(onStatus: onSpeechStatus);
    setState(() {});
  }

  //Esto sucede cada vez que se presiona el botón de hablar, para iniciar el reconocimiento de voz
  void startListening() async {
    isUserStopped = false;
    if (isListening) {
      await speechToText.listen(onResult: onSpeechResult);
      isSpeechEnabled = true;
    }
  }

  void onSpeechStatus(String status) {
    if (status == 'notListening' && isSpeechEnabled && !isUserStopped) {
      // Reinicia la escucha si aún está habilitada
      Future.delayed(const Duration(milliseconds: 100), () {
        startListening();
      });
    }
  }

  //Esto sucede cada vez que se presiona el botón de hablar, para detener el reconocimiento de voz
  void stopListening() async {
    isUserStopped = true;
    await speechToText.stop();
    isSpeechEnabled = false;
    fullTranscription = '';
    // setState(() {});
  }

  //Esto sucede cada vez que se detecta un resultado del reconocimiento de voz
  void onSpeechResult(SpeechRecognitionResult result) {
    lastWords = result.recognizedWords;
    lastWordsNotifier.value = lastWords;
    // Acumular transcripción continua
    if (result.finalResult) {
      fullTranscription += '${result.recognizedWords} ';
    }
  }

  Future<_UserHomeData> _fetchUserData(usuario) async {
    double saldo = 0.0;
    List<_ExpenseCardData> featuredExpenses = [];
    List<Transaccion> todasTransacciones = [];
    if (usuario != null) {
      saldo = await DatabaseHelper.instance.getSaldoTotal(usuario.id!);
      todasTransacciones = await DatabaseHelper.instance.getTransacciones(
        userId: usuario.id!,
      );
    }
    // Mapea ids de categoría a nombre y a icono
    Map<int, String> categoriaNombres = {};
    Map<int, int> categoriaIconos = {};
    for (final t in todasTransacciones) {
      if (!categoriaNombres.containsKey(t.categoryId)) {
        final cat = await DatabaseHelper.instance.getCategoriaById(
          t.categoryId,
        );
        categoriaNombres[t.categoryId] = cat?.name ?? 'Sin categoría';
        categoriaIconos[t.categoryId] = cat?.iconCode ?? Icons.category.codePoint;
      }
    }
    // Solo si hay transacciones
    if (todasTransacciones.isNotEmpty) {
      // Ordena por fecha descendente (más reciente primero)
      todasTransacciones.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
      // Las 3 más recientes para las tarjetas
      final recientes = todasTransacciones.take(3).toList();
      for (final t in recientes) {
        final isIngreso = t.type == 'ingreso';
        final formattedAmount = numberFormat.format(t.amount);
        final amountStr =
            '${isIngreso ? '+ ' : '- '}\$$formattedAmount';
        final amountColor = isIngreso ? Color(0xFF00BFA5) : Color(0xFFD32F2F);
        final iconCode = categoriaIconos[t.categoryId] ?? Icons.category.codePoint;
        featuredExpenses.add(
          _ExpenseCardData(
            icon: IconData(iconCode, fontFamily: 'MaterialIcons'),
            category: categoriaNombres[t.categoryId] ?? 'Sin categoría',
            amount: amountStr,
            date: t.date != null ? _formatDate(DateTime.parse(t.date!)) : '',
            color: amountColor, // SOLO para el monto
          ),
        );
      }
    }
    final formattedSaldo = numberFormat.format(saldo);
    return _UserHomeData(
      balance: '\$$formattedSaldo',
      featuredExpenses: featuredExpenses,
      allTransactions: todasTransacciones,
      categoriaNombres: categoriaNombres,
      categoriaIconos: categoriaIconos,
    );
  }


    int _selectedIndex = 0;
    bool _iconChanged = false;

    void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountsScreen()),
        ).then((_) => setState(() {}));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateTransactionScreen()),
        ).then((_) => setState(() {}));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Reportes()),
        ).then((_) => setState(() {}));
        break;
    }
  }

  void _handleLongPress() {
    setState(() {
      _iconChanged = !_iconChanged;
      if (_iconChanged) {
        startListening();
      } else {
        stopListening();
        lastWordsNotifier.value = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<UserProvider>(context).usuario;
    final String userName = usuario?.name ?? '';
    final String date = _formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: SafeArea(
        child: FutureBuilder<_UserHomeData>(
          future: _fetchUserData(usuario),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No hay datos para mostrar'));
            }
            final data = snapshot.data!;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Encabezado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Chreosis',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 164, 185, 183),
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Image.asset(
                              'assets/Colibri.png',
                              width: 39,
                              height: 39,
                            ),
                            // SizedBox(
                            //   width: 38,
                            //   height: 38,
                            //   child: rive.RiveAnimation.asset(
                            //     'assets/Colibri.riv',
                            //     fit: BoxFit.contain,
                            //   ),
                            // ),
                          ],
                        ),
                        GestureDetector(
                          onTap:
                              () =>
                                  Navigator.pushNamed(context, '/preferences'),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color.fromARGB(
                              255,
                              68,
                              66,
                              66,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Tarjeta de usuario
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 29, 29, 29),
                            Color.fromARGB(255, 28, 64, 80),
                          ],
                        ),

                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty ? 'Hola, $userName' : 'Hola',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Saldo Total',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.balance,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 164, 185, 183),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (data.featuredExpenses.isNotEmpty) ...[
                      const Text(
                        'Últimas transacciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tarjetas de los 3 más recientes (fade-in)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.featuredExpenses.length,
                        itemBuilder: (context, index) {
                          final exp = data.featuredExpenses[index];
                          return _AnimatedExpenseCard(
                            expense: exp,
                            index: index,
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Lista de transacciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Lista de transacciones (fade-in, excluyendo los 3 más recientes)
                      _AnimatedExpenseList(
                        allTransactions: data.allTransactions,
                        categoriaNombres: data.categoriaNombres,
                        categoriaIconos: data.categoriaIconos,
                        onTransaccionEliminada: () {
                          setState(() {});
                        },
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      //! --- BOTÓN SOLO PARA USO DE DESARROLLO ---
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     await DatabaseHelper.instance.deleteAllTransacciones();
      //     if (context.mounted) {
      //       setState(() {});
      //       ScaffoldMessenger.of(context).showSnackBar(
      //         const SnackBar(content: Text('Todas las transacciones han sido borradas (SOLO DESARROLLO)')),
      //       );
      //     }
      //   },
      //   backgroundColor: Colors.redAccent,
      //   child: const Icon(Icons.delete_forever),
      //   tooltip: 'Borrar todas las transacciones (SOLO DESARROLLO)',
      // ),
      //! --- FIN BOTÓN SOLO DESARROLLO ---
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ValueListenableBuilder<String>(
            valueListenable: lastWordsNotifier,
            builder: (context, lastWords, child) {
              return (isSpeechEnabled && lastWords.isNotEmpty)
                  ? Container(
                    margin: const EdgeInsets.only(bottom: 70),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Text(
                      lastWords,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  )
                  : const SizedBox.shrink();
            },
          ),
          BottomAppBar(
            color: Colors.grey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.home,
                    color:
                        _selectedIndex == 0
                            ? Colors.white
                            : Color.fromARGB(255, 172, 171, 171),
                  ),
                  onPressed: () => _onItemTapped(0),
                ),
                GestureDetector(
                  onLongPress: _handleLongPress,
                  child: IconButton(
                    icon: Icon(
                      Icons.wallet,
                      color:
                          _selectedIndex == 1
                              ? Colors.white
                              : Color.fromARGB(255, 172, 171, 171),
                    ),
                    onPressed: () => _onItemTapped(1),
                  ),
                ),
                GestureDetector(
                  onLongPress: _handleLongPress,
                  child: IconButton(
                    icon: Icon(
                      _iconChanged ? Icons.mic : Icons.add,
                      color:
                          _selectedIndex == 2
                              ? Colors.white
                              : Color.fromARGB(255, 172, 171, 171),
                    ),
                    onPressed: () => _onItemTapped(2),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.bar_chart,
                    color:
                        _selectedIndex == 3
                            ? Colors.white
                            : Color.fromARGB(255, 172, 171, 171),
                  ),
                  onPressed: () => _onItemTapped(3),
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/APP chreosis.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      _selectedIndex == 4
                          ? Colors.white
                          : Color.fromARGB(255, 172, 171, 171),
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => _onItemTapped(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedExpenseList extends StatefulWidget {
  final List<Transaccion> allTransactions;
  final Map<int, String> categoriaNombres;
  final Map<int, int> categoriaIconos;
  final VoidCallback? onTransaccionEliminada;
  const _AnimatedExpenseList({
    required this.allTransactions,
    required this.categoriaNombres,
    required this.categoriaIconos,
    this.onTransaccionEliminada,
  });

  @override
  State<_AnimatedExpenseList> createState() => _AnimatedExpenseListState();
}

class _AnimatedExpenseListState extends State<_AnimatedExpenseList> {
  double _opacity = 0.0;

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
          final nombreCategoria =
              widget.categoriaNombres[t.categoryId] ?? 'Sin categoría';
          final isIngreso = t.type == 'ingreso';
          final numberFormat = NumberFormat('#,##0.00', 'en_US');
          final formattedAmount = numberFormat.format(t.amount);
          final amountStr = '${isIngreso ? '+ ' : '- '}\$$formattedAmount';
          final amountColor = isIngreso ? Color(0xFF00BFA5) : Color(0xFFD32F2F);
          final iconCode = widget.categoriaIconos[t.categoryId] ?? Icons.category.codePoint;
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
              if (t.id != null) {
                final ok = await DatabaseHelper.instance.deleteTransaccion(
                  t.id!,
                );
                if (ok && mounted) {
                  if (widget.onTransaccionEliminada != null) {
                    widget.onTransaccionEliminada!();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transacción eliminada y saldo revertido.'),
                    ),
                  );
                }
              }
            },
            child: _ExpenseCardBase(
              icon: icon,
              category: nombreCategoria,
              amount: amountStr,
              date: formattedDate,
              amountColor: amountColor,
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseCardBase extends StatelessWidget {
  final IconData icon;
  final String category;
  final String amount;
  final String date;
  final Color amountColor;
  final double marginBottom;

  const _ExpenseCardBase({
    required this.icon,
    required this.category,
    required this.amount,
    required this.date,
    required this.amountColor,
    this.marginBottom = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE1F5E9),
            child: Icon(icon, color: const Color(0xFF212121)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 174, 185, 190),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedExpenseCard extends StatefulWidget {
  final _ExpenseCardData expense;
  final int index;

  const _AnimatedExpenseCard({
    required this.expense,
    required this.index,
  });

  @override
  State<_AnimatedExpenseCard> createState() => _AnimatedExpenseCardState();
}

class _AnimatedExpenseCardState extends State<_AnimatedExpenseCard> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 200), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: _ExpenseCardBase(
        icon: widget.expense.icon,
        category: widget.expense.category,
        amount: widget.expense.amount,
        date: widget.expense.date,
        amountColor: widget.expense.color,
      ),
    );
  }
}
