class CorridaModel {
  CorridaModel(
      this.id,
      this.data,
      this.cancelamentoAdministrativo,
      this.dataInicioCorrida,
      this.email,
      this.endereco,
      this.formaPagamento,
      this.km,
      this.motoca,
      this.nome,
      this.preco,
      this.status,
      this.telefone,
      this.tempoDestino,
      this.troco,
      this.userId);

  String id;
  DateTime data;
  String cancelamentoAdministrativo;
  DateTime dataInicioCorrida;
  String email;
  EnderecoModel endereco;
  String formaPagamento;
  String km;
  MotocaModel motoca;
  String nome;
  String preco;
  String status;
  String telefone;
  String tempoDestino;
  String troco;
  String userId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data,
        'cancelamentoAdministrativo': cancelamentoAdministrativo,
        'dataInicioCorrida': dataInicioCorrida,
        'email': email,
        'endereco': endereco.toJson(),
        'formaPagamento': formaPagamento,
        'km': km,
        'motoca': motoca.toJson(),
        'nome': nome,
        'preco': preco,
        'status': status,
        'telefone': telefone,
        'tempoDestino': tempoDestino,
        'troco': troco,
        'userId': userId,
      };

  // CorridaModel.fromJson(Map<String, dynamic> json) {
  //   latLongEnderecoOrigem = LatLng(
  //       json['latLongEnderecoOrigem'][0], json['latLongEnderecoOrigem'][1]);
  //   latLongEnderecoDestino = LatLng(
  //       json['latLongEnderecoDestino'][0], json['latLongEnderecoDestino'][1]);
  //   enderecoDestino = json['enderecoDestino'];
  //   enderecoOrigem = json['enderecoOrigem'];
  //   cidade = json['cidade'];
  // }
}

class EnderecoModel {
  EnderecoModel(this.cidade, this.enderecoDestino, this.enderecoOrigem,
      this.LatLongEnderecoDestino, this.LatLongEnderecoOrigem);

  String cidade;
  String enderecoDestino;
  String enderecoOrigem;
  List<double> LatLongEnderecoDestino;
  List<double> LatLongEnderecoOrigem;

  Map<String, dynamic> toJson() => {
        'cidade': cidade,
        'enderecoDestino': enderecoDestino,
        'enderecoOrigem': enderecoOrigem,
        'LatLongEnderecoDestino': LatLongEnderecoDestino,
        'LatLongEnderecoOrigem': LatLongEnderecoOrigem,
      };
}

class MotocaModel {
  MotocaModel(
      this.cidade,
      this.cnh,
      this.dataCadastro,
      this.dataNascimento,
      this.disponivel,
      this.email,
      this.motos,
      this.nomeCompleto,
      this.telefone,
      this.userId);
  String cidade;
  String cnh;
  DateTime dataCadastro;
  DateTime dataNascimento;
  String disponivel;
  String email;
  List<MotosModel> motos;
  String nomeCompleto;
  String telefone;
  String userId;

  Map<String, dynamic> toJson() => {
        'cidade': cidade,
        'cnh': cnh,
        'dataCadastro': dataCadastro,
        'dataNascimento': dataNascimento,
        'disponivel': disponivel,
        'email': email,
        'motos': motos.toList(),
        'nomeCompleto': nomeCompleto,
        'telefone': telefone,
        'userId': userId,
      };
}

class MotosModel {
  MotosModel(this.ano, this.cor, this.id, this.marca, this.placa, this.status);
  String ano;
  String cor;
  String id;
  String marca;
  String placa;
  String status;

  Map<String, dynamic> toJson() => {
        'ano': ano,
        'cor': cor,
        'id': id,
        'marca': marca,
        'placa': placa,
        'status': status,
      };
}
