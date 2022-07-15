class Usuario {
  Usuario();

  String foto = "";
  String email = "";
  String nome = "";
  String celular = "";

  Map<String, dynamic> toJson() => {
        'foto': foto,
        'email': email,
        'nome': nome,
        'celular': celular,
      };

  Usuario.fromJson(Map<String, dynamic> json) {
    foto = json['photoURL'];
    foto = json['email'];
    foto = json['displayName'];
    foto = json['phoneNumber'];
  }
}
