class TasaCambio {
  final String base;
  final String destino;
  final double tasa;
  final DateTime fecha;

  TasaCambio({
    required this.base,
    required this.destino,
    required this.tasa,
    required this.fecha,
  });

  factory TasaCambio.fromMap(Map<String, dynamic> map) {
    return TasaCambio(
      base: map['base'] ?? '',
      destino: map['destino'] ?? '',
      tasa: (map['tasa'] ?? 0).toDouble(),
      fecha: DateTime.parse(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'base': base,
      'destino': destino,
      'tasa': tasa,
      'fecha': fecha.toIso8601String(),
    };
  }
}
