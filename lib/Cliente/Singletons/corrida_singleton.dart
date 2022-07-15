class SingletonCorrida {
  static SingletonCorrida _instance = SingletonCorrida._();
  bool corridaAtiva = false;
  String corridaId = "";
  String usuarioId = "";
  String tempoMinimoMinutoParaCancelarCorrida = "";
  SingletonCorrida._();

  static SingletonCorrida get instance => _instance;

  bool getCorridaAtiva() {
    return corridaAtiva;
  }

  String getCorridaId() {
    return corridaId;
  }

  String getUsuarioId() {
    return usuarioId;
  }

  String getTempoMinimoMinutoParaCancelarCorrida() {
    return tempoMinimoMinutoParaCancelarCorrida;
  }

  void setTempoMinimoMinutoParaCancelarCorrida(
      String tempoMinimoMinutoParaCancelarCorrida) {
    this.tempoMinimoMinutoParaCancelarCorrida =
        tempoMinimoMinutoParaCancelarCorrida;
  }

  void setUsuarioId(String usuarioId) {
    this.usuarioId = usuarioId;
  }

  void setCorridaAtiva(bool corridaAtiva) {
    this.corridaAtiva = corridaAtiva;
  }

  void setCorridaId(String corridaId) {
    this.corridaId = corridaId;
  }
}
