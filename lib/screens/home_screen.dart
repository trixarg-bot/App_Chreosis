// ignore_for_file: avoid_print, use_build_context_synchronously
//TODO: dejar que la IA haga centralize la logica de negocio en cuanto a lo que tiene que ver con el formateo de montos, fechas, mapeo de categorias, etc
import 'package:flutter/material.dart';
import 'accounts_screen.dart';
import 'create_transaction_screen.dart';
import 'package:provider/provider.dart';
import '../screens/reportes_screen.dart';
import '../models/transaccion.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../db/database_helper.dart';
import 'package:intl/intl.dart';
import '../utils/gpt_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/categoria_provider.dart';
import '../models/categoria.dart';
import '../widgets/animated_expense_list.dart';
import '../widgets/animate_expense_card.dart';
import '../providers/cuenta_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class ExpenseCardData {
  final IconData icon;
  final String category;
  final String amount;
  final String date;
  final Color color;
  ExpenseCardData({
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final numberFormat = NumberFormat('#,##0.00', 'en_US');
  final SpeechToText speechToText = SpeechToText();
  bool isSpeechEnabled =
      false; // Indica si el reconocimiento de voz está habilitado
  bool isUserStopped = false; // Indica si el usuario ha detenido la escucha
  bool isListening = false; // Indica si el reconocimiento de voz está en curso
  String lastWords = ''; // Últimas palabras reconocidas
  final ValueNotifier<String> lastWordsNotifier = ValueNotifier(
    '',
  ); // Notificador para las últimas palabras reconocidas
  String fullTranscription =
      ''; // Transcripción  completa de lo que ha dicho el usuario
  bool isSpeechEnabled2 = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    initSpeech();
    final usuario =
        Provider.of<UsuarioProvider>(context, listen: false).usuario;
    if (usuario == null) return;
    Provider.of<TransactionProvider>(
      context,
      listen: false,
    ).cargarTransacciones(usuario.id!);
    Provider.of<UsuarioProvider>(
      context,
      listen: false,
    ).getSaldoTotal(usuario.id!);
    Provider.of<CategoriaProvider>(
      context,
      listen: false,
    ).cargarCategorias(usuario.id!);
    Provider.of<CuentaProvider>(
      context,
      listen: false,
    ).cargarCuentas(usuario.id!);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Duración de la animación
      vsync: this,
    )..repeat(reverse: true); // Hace que la animación se repita

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5, // Escala máxima del efecto
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      await speechToText.listen(
        onResult: onSpeechResult,
        localeId: 'es_ES',
        listenOptions: SpeechListenOptions(listenMode: ListenMode.confirmation),
      );
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
    if (fullTranscription.trim().isEmpty && lastWords.trim().isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se detectó ninguna transcripción')),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible:
            false, // Evita que el usuario cierre el diálogo tocando fuera
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
    try {
      final categoriaProvider = Provider.of<CategoriaProvider>(
        context,
        listen: false,
      );
      final categorias = categoriaProvider.categorias;
      final datos = await GptService().enviarTranscripcion(
        fullTranscription,
        categorias,
      );

      // Cerrar el diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
      }
      // Verificar si hay datos válidos
      if ((double.tryParse(datos.monto) ?? 0) > 0) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateTransactionScreen(datosGPT: datos),
          ),
        );

        if (result == true && mounted) {
          setState(() {});
          // Cuando se crea una transacción exitosamente, necesitamos:
          // 1. Obtener el usuario actual
          // 2. Recargar las transacciones para actualizar la lista
          // 3. Recargar las cuentas para actualizar el saldo
          final usuario =
              Provider.of<UsuarioProvider>(context, listen: false).usuario;
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).cargarTransacciones(usuario!.id!);
          await Provider.of<CuentaProvider>(
            context,
            listen: false,
          ).cargarCuentas(usuario.id!);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo procesar la transacción. Intenta de nuevo.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      // En caso de error, cerrar el diálogo y mostrar mensaje
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la solicitud. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      fullTranscription = '';
    }
  }

  //*Esto sucede cada vez que se detecta un resultado del reconocimiento de voz
  void onSpeechResult(SpeechRecognitionResult result) {
    lastWords = result.recognizedWords;
    lastWordsNotifier.value = lastWords;
    // Acumular transcripción continua
    fullTranscription += '${result.recognizedWords} ';
  }

  int _selectedIndex = 0;
  bool _iconChanged = false;

  void _onItemTapped(int index) {
    if (index == 0) {
      setState(() => _selectedIndex = 0);
      return;
    }

    setState(() => _selectedIndex = index);

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountsScreen()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateTransactionScreen(),
          ),
        ).then((_) async {
          setState(() => _selectedIndex = 0);
          //después de crear una transacción:
          // 1. Actualizamos el índice seleccionado
          // 2. Recargamos transacciones y cuentas para reflejar los cambios
          final usuario =
              Provider.of<UsuarioProvider>(context, listen: false).usuario;
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).cargarTransacciones(usuario!.id!);
          await Provider.of<CuentaProvider>(
            context,
            listen: false,
          ).cargarCuentas(usuario.id!);
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Reportes()),
        ).then((_) => setState(() => _selectedIndex = 0));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    //* Inicializamos los providers
    final usuario = Provider.of<UsuarioProvider>(context).usuario;
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final categoriaProvider =
        Provider.of<CategoriaProvider>(context).categorias;

    //* Obtenemos el nombre del usuario y la fecha actual
    final String userName = usuario?.name ?? '';
    final String date = _formatDate(DateTime.now());

    //* Obtenemos la lista de transacciones, el saldo y el mapa de categorías
    List<Transaccion> todasTransacciones = transactionProvider.transacciones;
    final Map<int, Categoria> mapaCategorias = {
      for (final cat in categoriaProvider) cat.id!: cat,
    };
    final recientes =
        todasTransacciones.length > 3
            ? todasTransacciones.take(3).toList()
            : todasTransacciones;

    List<ExpenseCardData> featuredExpenses =
        recientes.map((t) {
          final cat = mapaCategorias[t.categoryId];
          final isIngreso = t.type == 'ingreso';
          final formattedAmount = numberFormat.format(t.amount);
          final amountStr = '${isIngreso ? '+ ' : '- '}\$$formattedAmount';
          final amountColor = isIngreso ? Color(0xFF00BFA5) : Color(0xFFD32F2F);
          final iconCode = cat?.iconCode ?? Icons.category.codePoint;

          return ExpenseCardData(
            icon: IconData(iconCode, fontFamily: 'MaterialIcons'),
            category: cat?.name ?? 'Sin categoría',
            amount: amountStr,
            date: t.date != null ? _formatDate(DateTime.parse(t.date!)) : '',
            color: amountColor,
          );
        }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: SafeArea(
        child: SingleChildScrollView(
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
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/preferences'),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color.fromARGB(255, 68, 66, 66),
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
                //* Tarjeta de usuario
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        // mainAxisSize: MainAxisSize.max,
                        children: [
                          Consumer<CuentaProvider>(
                            builder: (context, cuentaProvider, child) {
                              // Este Consumer escucha cambios en las cuentas y recalcula el saldo
                              // cada vez que hay una modificación en CuentaProvider;
                              double saldo = cuentaProvider.cuentas
                                  .fold<double>(
                                    0.0,
                                    (total, cuenta) => total + cuenta.amount,
                                  );
                              return Text(
                                numberFormat.format(saldo),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 164, 185, 183),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isSpeechEnabled2
                                          ? Colors.blue.withOpacity(0.2)
                                          : Colors.transparent,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isSpeechEnabled2)
                                      Transform.scale(
                                        scale: _scaleAnimation.value,
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.blue.withOpacity(0.3),
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      color:
                                          isSpeechEnabled2
                                              ? Colors.blue
                                              : Colors.grey[400],
                                      iconSize: 28,
                                      padding: const EdgeInsets.all(8),
                                      icon: Icon(
                                        isSpeechEnabled2
                                            ? Icons.mic
                                            : Icons.mic_off,
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          isSpeechEnabled2 = !isSpeechEnabled2;
                                          if (isSpeechEnabled2) {
                                            _animationController.repeat(
                                              reverse: true,
                                            );
                                            startListening();
                                          } else {
                                            _animationController.stop();
                                            stopListening();
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (featuredExpenses.isNotEmpty) ...[
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
                  Consumer2<TransactionProvider, CuentaProvider>(
                    builder: (
                      context,
                      transactionProvider,
                      cuentaProvider,
                      child,
                    ) {
                      List<Transaccion> todasTransacciones =
                          transactionProvider.transacciones;
                      final usuario =
                          Provider.of<UsuarioProvider>(
                            context,
                            listen: false,
                          ).usuario;

                      final recientes =
                          todasTransacciones.length > 3
                              ? todasTransacciones.take(3).toList()
                              : todasTransacciones;

                      Future<void> eliminarTransaccion(
                        Transaccion transaccion,
                      ) async {
                        try {
                          await Provider.of<TransactionProvider>(
                            context,
                            listen: false,
                          ).deleteTransaccion(
                            transaccion.id!,
                            transaccion.userId,
                          );

                          // Actualizar después de eliminar
                          if (context.mounted) {
                            await Provider.of<TransactionProvider>(
                              context,
                              listen: false,
                            ).cargarTransacciones(usuario!.id!);
                            await Provider.of<CuentaProvider>(
                              context,
                              listen: false,
                            ).cargarCuentas(usuario.id!);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transacción eliminada'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error al eliminar la transacción',
                                ),
                              ),
                            );
                          }
                        }
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recientes.length,
                        itemBuilder: (context, index) {
                          final transaccion = recientes[index];
                          final cat = mapaCategorias[transaccion.categoryId];

                          return Dismissible(
                            key: Key(transaccion.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              color: Colors.red,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
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
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmar == true) {
                                await eliminarTransaccion(transaccion);
                                return true;
                              }
                              return false;
                            },
                            child: AnimatedExpenseCard(
                              expense: ExpenseCardData(
                                icon: IconData(
                                  cat?.iconCode ?? Icons.category.codePoint,
                                  fontFamily: 'MaterialIcons',
                                ),
                                category: cat?.name ?? 'Sin categoría',
                                amount:
                                    '${transaccion.type == 'ingreso' ? '+ ' : '- '}\$${numberFormat.format(transaccion.amount)}',
                                date:
                                    transaccion.date != null
                                        ? _formatDate(
                                          DateTime.parse(transaccion.date!),
                                        )
                                        : '',
                                color:
                                    transaccion.type == 'ingreso'
                                        ? const Color(0xFF00BFA5)
                                        : const Color(0xFFD32F2F),
                              ),
                              index: index,
                            ),
                          );
                        },
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
                  AnimatedExpenseList(
                    allTransactions: todasTransacciones,
                    mapaCategorias: mapaCategorias,
                    onTransaccionEliminada: () async {
                      // Cuando se elimina una transacción:
                      // 1. Obtenemos el usuario actual
                      // 2. Recargamos las transacciones para actualizar la lista
                      // 3. Recargamos las cuentas para actualizar el saldo
                      final usuario =
                          Provider.of<UsuarioProvider>(
                            context,
                            listen: false,
                          ).usuario;
                      await Provider.of<TransactionProvider>(
                        context,
                        listen: false,
                      ).cargarTransacciones(usuario!.id!);
                      await Provider.of<CuentaProvider>(
                        context,
                        listen: false,
                      ).cargarCuentas(usuario.id!);
                    },
                  ),
                ],
              ],
            ),
          ),
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
                    margin: const EdgeInsets.only(bottom: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
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
                IconButton(
                  icon: Icon(
                    Icons.wallet,
                    color:
                        _selectedIndex == 1
                            ? Colors.white
                            : Color.fromARGB(255, 172, 171, 171),
                  ),
                  onPressed: () => _onItemTapped(1),
                ),
                IconButton(
                  icon: Icon(
                    _iconChanged ? Icons.mic : Icons.add,
                    color:
                        _selectedIndex == 2
                            ? Colors.white
                            : Color.fromARGB(255, 172, 171, 171),
                  ),
                  onPressed: () => _onItemTapped(2),
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
