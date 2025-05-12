import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:chreosis_app/user_provider.dart';
import 'package:chreosis_app/page_reportes_helper.dart';
import 'package:chreosis_app/models/transaccion.dart';
import 'package:chreosis_app/models/categoria.dart';
import 'package:chreosis_app/db/database_helper.dart';


class Reportes extends StatefulWidget {
  @override
  State<Reportes> createState() => _ReportesState();
}


class _PeriodoButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodoButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onTap,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: selected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 2),
            height: 1.5,
            width: 40,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ],
      ),
    );
  }
}

// Continúa el resto de la clase _ReportesState como estaba...
class _ReportesState extends State<Reportes> {
  String _selectedValue = 'gastos';
  int _selectedButton = 0; // 0: Hoy, 1: Semana, 2: Mes

  Map<int, Categoria> _categoriasPorId = {};

  @override
  void initState() {
    super.initState();
    _loadCategorias();
    _loadData();
  }

  Future<void> _loadCategorias() async {
    final userId = Provider.of<UserProvider>(context, listen: false).usuario?.id;
    if (userId == null) return;
    final categorias = await DatabaseHelper.instance.getCategorias(userId: userId);
    setState(() {
      _categoriasPorId = {for (var c in categorias) c.id!: c};
    });
  }

  Future<List<CategoriaPorcentaje>>? _futureCategorias;

  void _loadData() {
    final userId = Provider.of<UserProvider>(context, listen: false).usuario?.id;
    if (userId == null) return;
    final now = DateTime.now();
    DateTime desde;
    if (_selectedButton == 0) {
      // Hoy
      desde = DateTime(now.year, now.month, now.day);
    } else if (_selectedButton == 1) {
      // Semana
      desde = now.subtract(const Duration(days: 6));
      desde = DateTime(desde.year, desde.month, desde.day);
    } else {
      // Mes
      desde = DateTime(now.year, now.month, 1);
    }
    final hasta = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _futureCategorias = ReportesDataHelper.obtenerPorcentajesCategorias(
      userId: userId,
      tipo: _selectedValue,
      desde: desde,
      hasta: hasta,
    );
  }

  void _onFiltroChanged(String? value) {
    setState(() {
      _selectedValue = value!;
      _loadData();
    });
  }

  void _onPeriodoChanged(int index) {
    setState(() {
      _selectedButton = index;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: Text('Reportes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 25, // Distancia desde la parte superior
            left: 8, // Distancia desde la izquierda
            child: SizedBox(
              width: 150,
              child: DropdownButtonFormField<String>(
                iconSize: 0,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: Colors.grey[850],
                borderRadius: BorderRadius.circular(15),
                menuMaxHeight: 200,
                style: TextStyle(color: Colors.white, fontSize: 16),
                value: _selectedValue,
                onChanged: _onFiltroChanged,
                items: [
                  DropdownMenuItem<String>(
                    value: 'gastos',
                    child: Row(
                      children: [
                        Text('Gastos', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 20),
                        Icon(Icons.trending_down, color: Colors.redAccent),
                      ],
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'ingresos',
                    child: Row(
                      children: [
                        Text('Ingresos', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 20),
                        Icon(Icons.trending_up, color: Colors.lightGreenAccent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 120, left: 8, right: 8),
            child: Row(
              children: [
                _PeriodoButton(
                  label: 'Hoy',
                  selected: _selectedButton == 0,
                  onTap: () => _onPeriodoChanged(0),
                ),
                _PeriodoButton(
                  label: 'Semana',
                  selected: _selectedButton == 1,
                  onTap: () => _onPeriodoChanged(1),
                ),
                _PeriodoButton(
                  label: 'Mes',
                  selected: _selectedButton == 2,
                  onTap: () => _onPeriodoChanged(2),
                ),
              ],
            ),
          ),
          Positioned(
            top: 200,
            left: 16,
            right: 16,
            child: Container(
              height: 220,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
              ),
              child: FutureBuilder<List<CategoriaPorcentaje>>(
                future: _futureCategorias,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return Center(child: Text('No hay datos para mostrar', style: TextStyle(color: Colors.white70)));
                  }
                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < 0 || value.toInt() >= data.length) return SizedBox();
                              return Text(
                                data[value.toInt()].categoria.name,
                                style: TextStyle(color: Colors.white, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                            reservedSize: 40,
                            interval: 1,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                            // Mostrar 0, 25, 50, 75, 100
                            if (value % 25 == 0) {
                              return Text('${value.toInt()}%', style: TextStyle(color: Colors.white, fontSize: 10));
                            }
                            return SizedBox();
                          }, reservedSize: 28, interval: 25),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1)),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data[index].porcentaje,
                              color: _selectedValue == 'gastos' ? Colors.redAccent : Colors.lightGreenAccent,
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ),
          // Lista de transacciones filtradas debajo del gráfico
          Positioned(
            top: 440,
            left: 16,
            right: 16,
            bottom: 0,
            child: FutureBuilder<List<Transaccion>>(
              future: ReportesDataHelper.obtenerTransaccionesFiltradas(
                userId: Provider.of<UserProvider>(context, listen: false).usuario?.id ?? 0,
                tipo: _selectedValue,
                desde: _selectedButton == 0
                    ? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
                    : _selectedButton == 1
                        ? DateTime.now().subtract(const Duration(days: 6))
                        : DateTime(DateTime.now().year, DateTime.now().month, 1),
                hasta: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                final transacciones = snapshot.data ?? [];
                if (transacciones.isEmpty) {
                  return Center(child: Text('No hay transacciones para mostrar', style: TextStyle(color: Colors.white70)));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: transacciones.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = transacciones[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: t.type == 'gasto' ? Colors.redAccent : Colors.lightGreenAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Mostrar icono y nombre de la categoría
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: t.type == 'gasto' ? Colors.redAccent : Colors.lightGreenAccent,
                            child: Icon(
                              _categoriasPorId[t.categoryId]?.iconCode != null
                                  ? IconData(_categoriasPorId[t.categoryId]!.iconCode, fontFamily: 'MaterialIcons')
                                  : Icons.category,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _categoriasPorId[t.categoryId]?.name ?? 'Sin categoría',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                Text(
                                  t.date != null ? t.date!.substring(0, 10) : '',
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            (t.type == 'ingreso' ? '+ ' : '- ') + '\$${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: t.type == 'gasto' ? Colors.redAccent : Colors.lightGreenAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 