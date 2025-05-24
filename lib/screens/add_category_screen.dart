import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';
import '../providers/categoria_provider.dart';
import '../widgets/lista_iconos.dart';


class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({Key? key}) : super(key: key);

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Gasto';
  IconData _selectedIcon = Icons.account_balance_wallet_rounded;
  bool _loading = false;

  // Lista para la selección de iconos
  Future<void> seleccionarIcono(BuildContext context) async {
    final iconoSeleccionado = await showDialog<IconData>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Selecciona un icono'),
          children:
              listaIconosPersonalizados.map((icono) {
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

  Color get emerald => const Color(0xFF00BFA5);
  Color get skyBlue => const Color(0xFF4FC3F7);
  Color get yellow => const Color(0xFFFFEB3B);
  Color get bgGray => const Color.fromARGB(255, 134, 133, 133);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UsuarioProvider>(context);
    final usuario = userProvider.usuario!;
    Provider.of<CategoriaProvider>(context, listen: false).cargarCategorias(usuario.id!,);
    // final categoriaProvider = Provider.of<CategoriaProvider>(context).categorias;

    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text(
          'Agregar Categoría',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(18),
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
                      const Text(
                        'Nombre de la categoría',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Transporte, Comida...',
                          hintStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          filled: true,
                          fillColor: bgGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tipo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Selector visual de icono para la categoría
                          GestureDetector(
                            onTap: () async {
                              final iconoSeleccionado = await showDialog<
                                IconData
                              >(
                                context: context,
                                builder: (ctx) {
                                  return SimpleDialog(
                                    title: const Text(
                                      'Selecciona un icono para la categoría',
                                    ),
                                    children:
                                        listaIconosCategorias.map((icono) {
                                          return ListTile(
                                            leading: Icon(
                                              icono['icon'],
                                              size: 32,
                                            ),
                                            title: Text(icono['label']),
                                            onTap:
                                                () => Navigator.pop(
                                                  ctx,
                                                  icono['icon'],
                                                ),
                                          );
                                        }).toList(),
                                  );
                                },
                              );
                              if (iconoSeleccionado != null) {
                                setState(
                                  () => _selectedIcon = iconoSeleccionado,
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color.fromARGB(
                                255,
                                37,
                                38,
                                39,
                              ),
                              child: Icon(
                                _selectedIcon,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          ChoiceChip(
                            label: const Text(
                              'Gasto',
                              style: TextStyle(color: Colors.white),
                            ),
                            selected: _selectedType == 'Gasto',
                            selectedColor: Color.fromARGB(255, 179, 13, 13),
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color:
                                  _selectedType == 'Gasto'
                                      ? Colors.white
                                      : emerald,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected:
                                (v) => setState(() => _selectedType = 'Gasto'),
                          ),
                          const SizedBox(width: 14),
                          ChoiceChip(
                            label: const Text(
                              'Ingreso',
                              style: TextStyle(color: Colors.white),
                            ),
                            selected: _selectedType == 'Ingreso',
                            selectedColor: Color.fromARGB(255, 11, 165, 9),
                            backgroundColor: Colors.grey[800],
                            labelStyle: TextStyle(
                              color:
                                  _selectedType == 'Ingreso'
                                      ? Colors.black
                                      : emerald,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected:
                                (v) =>
                                    setState(() => _selectedType = 'Ingreso'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                            elevation: 1,
                            backgroundColor: Color.fromARGB(82, 79, 74, 74),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed:
                              _loading
                                  ? null
                                  : () async {
                                    if (!_formKey.currentState!.validate())
                                      return;
                                    setState(() => _loading = true);
                                    
                                    try {
                                      final categoriaProvider = Provider.of<CategoriaProvider>(
                                        context,
                                        listen: false,
                                      );
                                      
                                      await categoriaProvider.insertCategoria(
                                        userId: usuario.id!,
                                        name: _nameController.text.trim(),
                                        type: _selectedType,
                                        iconCode: _selectedIcon.codePoint,
                                      );

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Categoría agregada exitosamente'),
                                          ),
                                        );
                                        Navigator.pop(context, true);
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Error al agregar la categoría'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      setState(() => _loading = false);
                                    }
                                  },
                          child:
                              _loading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Guardar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Tus categorías',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<CategoriaProvider>(
                  builder: (context, categoriaProvider, _) {
                    if (categoriaProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final categorias = categoriaProvider.categorias;
                    if (categorias.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aún no tienes categorías.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: categorias.length,
                      itemBuilder: (context, i) {
                        final cat = categorias[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[700],
                            child: Icon(
                              IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            cat.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            cat.type!,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 126, 125, 125),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red[300]),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('¿Eliminar categoría?'),
                                      content: const Text(
                                        '¿Estás seguro de que deseas eliminar esta categoría?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(true),
                                          child: const Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirm == true) {
                                try {
                                  await categoriaProvider.deleteCategoria(
                                    cat.id!,
                                    cat.userId,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Categoría eliminada correctamente',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al eliminar: ${e.toString()}',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
