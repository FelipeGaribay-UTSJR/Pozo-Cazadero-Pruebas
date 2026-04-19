class UserModel {
  final String uid;
  final String email;
  final String nombre;
  final String numeroMedidor;
  final String rol;
  final String? direccion;
  final double ultimaLectura;

  UserModel({
    required this.uid,
    required this.email,
    required this.nombre,
    required this.numeroMedidor,
    required this.rol,
    this.direccion,
    this.ultimaLectura = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      nombre: data['nombre'] ?? '',
      numeroMedidor: data['numeroMedidor'].toString(), // Forzar a String
      rol: data['rol'] ?? 'usuario',
      direccion: data['direccion'],
      ultimaLectura: (data['ultimaLectura'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nombre': nombre,
      'numeroMedidor': numeroMedidor,
      'rol': rol,
      'direccion': direccion,
      'fechaRegistro': DateTime.now(),
      'ultimaLectura': ultimaLectura,
    };
  }
}