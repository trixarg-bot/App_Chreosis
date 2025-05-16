class DatosTransaccion {
  final String monto;
  final String categoria;
  final String descripcion;
  final String metodoPago;
  final String fecha;
  final String tipoTransaccion;

  DatosTransaccion({
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.metodoPago,
    required this.fecha,
    required this.tipoTransaccion,
  });

  factory DatosTransaccion.fromJson(Map<String, dynamic> json) {
    return DatosTransaccion(
      monto: json['monto'] ?? '',
      categoria: json['categoria'] ?? '',
      descripcion: json['descripcion'] ?? '',
      metodoPago: json['metodoPago'] ?? '',
      fecha: json['fecha'] ?? '',
      tipoTransaccion: json['tipoTransaccion'] ?? '',
    );
  }
}

