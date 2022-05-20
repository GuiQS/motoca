import 'package:google_maps_flutter/google_maps_flutter.dart';

class Endereco {
  Endereco();

  LatLng latLongEnderecoOrigem = const LatLng(0, 0);
  LatLng latLongEnderecoDestino = const LatLng(0, 0);
  String enderecoOrigem = "";
  String enderecoDestino = "";
  String cidade = "";

  Map<String, dynamic> toJson() => {
        'latLongEnderecoOrigem': latLongEnderecoOrigem.toJson(),
        'latLongEnderecoDestino': latLongEnderecoDestino.toJson(),
        'enderecoOrigem': enderecoOrigem,
        'enderecoDestino': enderecoDestino,
        'cidade': cidade,
      };

  Endereco.fromJson(Map<String, dynamic> json) {
    latLongEnderecoOrigem = LatLng(
        json['latLongEnderecoOrigem'][0], json['latLongEnderecoOrigem'][1]);
    latLongEnderecoDestino = LatLng(
        json['latLongEnderecoDestino'][0], json['latLongEnderecoDestino'][1]);
    enderecoDestino = json['enderecoDestino'];
    enderecoOrigem = json['enderecoOrigem'];
    cidade = json['cidade'];
  }
}
