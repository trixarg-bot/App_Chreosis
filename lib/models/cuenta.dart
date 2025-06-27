class Cuenta {
  final int? id;
  final int userId;
  final String name;
  final String? type;
  final double amount;
  final String moneda;

  Cuenta({
    this.id,
    required this.userId,
    required this.name,
    this.type,
    required this.amount,
    required this.moneda,
  });

  // Conversión de Map (de la base de datos) a objeto Cuenta
  factory Cuenta.fromMap(Map<String, dynamic> map) => Cuenta(
    id: map['id'],
    userId: map['user_id'],
    name: map['name'],
    type: map['type'],
    amount: map['amount']?.toDouble() ?? 0.0,
    moneda: map['moneda'] ?? 'USD',
  );

  // Conversión de objeto Cuenta a Map (para la base de datos)
  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'type': type,
    'amount': amount,
    'moneda': moneda,
  };

  Cuenta copyWith({
    int? id,
    int? userId,
    String? name,
    String? type,
    double? amount,
    String? moneda,
  }) {
    return Cuenta(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      moneda: moneda ?? this.moneda,
    );
  }
}
