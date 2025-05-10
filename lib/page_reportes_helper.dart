import 'package:chreosis_app/db/database_helper.dart';
import 'package:chreosis_app/models/categoria.dart';
import 'package:chreosis_app/models/transaccion.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class CategoriaPorcentaje {
  final Categoria categoria;
  final double porcentaje;
  final double monto;
  CategoriaPorcentaje({required this.categoria, required this.porcentaje, required this.monto});
}

class ReportesDataHelper {
  /// Obtiene las transacciones filtradas por tipo y periodo para el usuario
  static Future<List<Transaccion>> obtenerTransaccionesFiltradas({
    required int userId,
    required String tipo, // 'gastos' o 'ingresos'
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final transacciones = await DatabaseHelper.instance.getTransacciones(userId: userId);
    final tipoFiltrado = tipo == 'gastos' ? 'gasto' : 'ingreso';
    final transaccionesFiltradas = transacciones.where((t) {
      if (t.type?.toLowerCase() != tipoFiltrado) return false;
      if (t.date == null) return false;
      final fecha = DateTime.tryParse(t.date!);
      if (fecha == null) return false;
      return fecha.isAfter(desde.subtract(const Duration(days: 1))) && fecha.isBefore(hasta.add(const Duration(days: 1)));
    }).toList();
    // Ordenar por fecha descendente
    transaccionesFiltradas.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
    return transaccionesFiltradas;
  }

  /// Obtiene la lista de categorias con su porcentaje de gasto/ingreso en el periodo y tipo seleccionado
  static Future<List<CategoriaPorcentaje>> obtenerPorcentajesCategorias({
    required int userId,
    required String tipo, // 'gastos' o 'ingresos'
    required DateTime desde,
    required DateTime hasta,
  }) async {
    // 1. Obtener todas las categorias del usuario
    final categorias = await DatabaseHelper.instance.getCategorias(userId: userId);
    // 2. Obtener todas las transacciones del usuario
    final transacciones = await DatabaseHelper.instance.getTransacciones(userId: userId);
    // 3. Filtrar por tipo y rango de fecha
    final tipoFiltrado = tipo == 'gastos' ? 'gasto' : 'ingreso';
    final transaccionesFiltradas = transacciones.where((t) {
      if (t.type?.toLowerCase() != tipoFiltrado) return false;
      if (t.date == null) return false;
      final fecha = DateTime.tryParse(t.date!);
      if (fecha == null) return false;
      return fecha.isAfter(desde.subtract(const Duration(days: 1))) && fecha.isBefore(hasta.add(const Duration(days: 1)));
    }).toList();
    // 4. Agrupar por categoria y sumar montos
    Map<int, double> sumaPorCategoria = {};
    for (final t in transaccionesFiltradas) {
      sumaPorCategoria[t.categoryId] = (sumaPorCategoria[t.categoryId] ?? 0) + (t.amount ?? 0);
    }
    // 5. Sumar total
    final total = sumaPorCategoria.values.fold(0.0, (a, b) => a + b);
    // 6. Crear lista de CategoriaPorcentaje
    List<CategoriaPorcentaje> lista = [];
    for (final entry in sumaPorCategoria.entries) {
      final cat = categorias.firstWhere((c) => c.id == entry.key, orElse: () => Categoria(id: entry.key, name: 'Sin categoría', userId: userId, type: tipoFiltrado, iconCode: 0));
      final porcentaje = total > 0 ? (entry.value / total) * 100 : 0.0;
      lista.add(CategoriaPorcentaje(categoria: cat, porcentaje: porcentaje, monto: entry.value));
    }
    // Ordenar de mayor a menor porcentaje
    lista.sort((a, b) => b.porcentaje.compareTo(a.porcentaje));
    return lista;
  }
}
