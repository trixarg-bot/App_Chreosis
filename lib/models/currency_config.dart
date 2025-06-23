class CurrencyConfig {
  final String monedaBase;
  final List<String> monedasSoportadas;
  final DateTime? ultimaActualizacion;

  CurrencyConfig({
    required this.monedaBase,
    required this.monedasSoportadas,
    this.ultimaActualizacion,
  });

  factory CurrencyConfig.fromMap(Map<String, dynamic> map) {
    return CurrencyConfig(
      monedaBase: map['monedaBase'] ?? '',
      monedasSoportadas: List<String>.from(map['monedasSoportadas'] ?? []),
      ultimaActualizacion:
          map['ultimaActualizacion'] != null
              ? DateTime.parse(map['ultimaActualizacion'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monedaBase': monedaBase,
      'monedasSoportadas': monedasSoportadas,
      'ultimaActualizacion': ultimaActualizacion?.toIso8601String(),
    };
  }
}
