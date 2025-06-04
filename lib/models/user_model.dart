class User {
  final int? id;
  final String username;
  final String password;
  final String? email;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      email: map['email'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
