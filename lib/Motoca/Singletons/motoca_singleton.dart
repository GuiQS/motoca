class SingletonMotoca {
  static SingletonMotoca _instance = SingletonMotoca._();

  String usuarioId = "";
  SingletonMotoca._();

  static SingletonMotoca get instance => _instance;

  String getUsuarioId() {
    return usuarioId;
  }

  void setUsuarioId(String usuarioId) {
    this.usuarioId = usuarioId;
  }
}
