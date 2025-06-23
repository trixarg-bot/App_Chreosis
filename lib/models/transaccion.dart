//TODO: AGREGAR LUGAR Al modelo de transaccion
class Transaccion {
  final int? id;
  final int userId;
  final int categoryId;
  final int accountId;
  final String? place;
  final String? date;
  final double amount;
  final String? type;
  final String? note;
  final String? attachment;
  final String? createdAt;
  final String moneda; // Código de moneda de la transacción
  final bool conversion; // Indica si hubo conversión de moneda
  final double? montoConvertido; // Monto convertido si aplica

  Transaccion({
    this.id,
    required this.userId,
    required this.categoryId,
    required this.accountId,
    this.place,
    this.date,
    required this.amount,
    this.type,
    this.note,
    this.attachment,
    this.createdAt,
    required this.moneda,
    required this.conversion,
    this.montoConvertido,
  });

  factory Transaccion.fromMap(Map<String, dynamic> map) => Transaccion(
    id: map['id'],
    userId: map['user_id'],
    categoryId: map['category_id'],
    accountId: map['account_id'],
    place: map['place'],
    date: map['date'],
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    type: map['type'],
    note: map['note'],
    attachment: map['attachment'],
    createdAt: map['created_at'],
    moneda: map['moneda'] ?? 'USD',
    conversion: map['conversion'] == 1 || map['conversion'] == true,
    montoConvertido: (map['monto_convertido'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'account_id': accountId,
    'place': place,
    'date': date,
    'amount': amount,
    'type': type,
    'note': note,
    'attachment': attachment,
    'created_at': createdAt,
    'moneda': moneda,
    'conversion': conversion ? 1 : 0,
    'monto_convertido': montoConvertido,
  };

  Transaccion copyWith({
    int? id,
    int? userId,
    int? categoryId,
    int? accountId,
    String? place,
    String? date,
    double? amount,
    String? type,
    String? note,
    String? attachment,
    String? createdAt,
    String? moneda,
    bool? conversion,
    double? montoConvertido,
  }) {
    return Transaccion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      place: place ?? this.place,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      attachment: attachment ?? this.attachment,
      createdAt: createdAt ?? this.createdAt,
      moneda: moneda ?? this.moneda,
      conversion: conversion ?? this.conversion,
      montoConvertido: montoConvertido ?? this.montoConvertido,
    );
  }
}
