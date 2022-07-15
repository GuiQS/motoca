import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import "package:google_maps_webservice/geocoding.dart";

exibirToastTop(String msg) {
  Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);
}

Future<Position> pegarLocalizacao() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Seu GPS está desabilitado');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Esta bloqueado para visualizar a localização');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Permissão para buscar localização negada');
  }

  return await Geolocator.getCurrentPosition();
}

Future<RetornoLatLongEndereco> latlongParaEndereco(
    double latitude, double longitude, String googleApiKey) async {
  final geocoding = GoogleMapsGeocoding(apiKey: googleApiKey);
  GeocodingResponse response =
      await geocoding.searchByLocation(Location(lat: latitude, lng: longitude));

  var cidade = response.results[0].addressComponents
      .where((componentsEndereco) =>
          componentsEndereco.types.first == "administrative_area_level_2" ||
          componentsEndereco.types.last == "administrative_area_level_2")
      .first
      .longName;
  if (cidade == "") {
    exibirToastTop("Não conseguimos identificar sua cidade");
    return Future.error("Não conseguimos identificar sua cidade");
  }

  return RetornoLatLongEndereco(
      cidade, response.results.first.formattedAddress.toString());
}

double calcularDistanciaEntreCoordenadas(
    startLatitude, startLongitude, endLatitude, endLongitude) {
  final double distance = Geolocator.distanceBetween(
      startLatitude, startLongitude, endLatitude, endLongitude);
  return distance / 1000;
}

class RetornoLatLongEndereco {
  String cidade = "";
  String enderecoFormatado = "";

  RetornoLatLongEndereco(this.cidade, this.enderecoFormatado);
}
