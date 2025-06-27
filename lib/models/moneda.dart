class Moneda {
  final String codigo;
  final String nombre;
  final String simbolo;

  Moneda({required this.codigo, required this.nombre, required this.simbolo});  

  

  factory Moneda.fromMap(Map<String, dynamic> map) {
    return Moneda(
      codigo: map['codigo'] ?? '',
      nombre: map['nombre'] ?? '',
      simbolo: map['simbolo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'codigo': codigo, 'nombre': nombre, 'simbolo': simbolo};
  }
}
