class DatosTransaccion {
  final String monto;
  final String categoria;
    final String lugar;
  final String descripcion;
  final String metodoPago;
  final String fecha;
  final String tipoTransaccion;
  DatosTransaccion({
    required this.monto,
    required this.categoria,
    required this.lugar,
    required this.descripcion,
    required this.metodoPago,
    required this.fecha,
    required this.tipoTransaccion,
  });

  factory DatosTransaccion.fromJson(Map<String, dynamic> json) {
    return DatosTransaccion(
      monto: json['monto'] ?? '',
      categoria: json['categoria'] ?? '',
      lugar: json['lugar'] ?? '',
      descripcion: json['descripcion'] ?? '',
      metodoPago: json['metodoPago'] ?? '',
      fecha: json['fecha'] ?? '',
      tipoTransaccion: json['tipoTransaccion'] ?? '',
    );
  }
}

