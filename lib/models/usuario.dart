class Usuario {
  final int? id;
  final String name;
  final String password;
  final String? email;
  final String? phoneNumber;
  final String? createdAt;

  Usuario({
    this.id,
    required this.name,
    required this.password,
    this.email,
    this.phoneNumber,
    this.createdAt,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
        id: map['id'],
        name: map['name'],
        password: map['password'],
        email: map['email'],
        phoneNumber: map['phone_number'],
        createdAt: map['created_at'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'password': password,
        'email': email,
        'phone_number': phoneNumber,
        'created_at': createdAt,
      };
}