import 'package:flutter/material.dart';

class Categoria {
  final int? id;
  final int userId;
  final String name;
  final String? type;
  final int iconCode;

  Categoria({
    this.id,
    required this.userId,
    required this.name,
    this.type,
    required this.iconCode,
  });

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['id'],
        userId: map['user_id'],
        name: map['name'],
        type: map['type'],
        iconCode: map['icon_code'] ?? Icons.category.codePoint
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type,
        'icon_code': iconCode,
      };
}