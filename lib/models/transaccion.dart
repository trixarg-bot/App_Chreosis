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
      };
}