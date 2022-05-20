import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Motoca/Cliente/controller/corrida_controller.dart';
import 'package:Motoca/Cliente/controller/usuario_controller.dart';
import 'package:Motoca/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../util.dart';
import 'model/endereco.model.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class InicioClient extends StatelessWidget {
  const InicioClient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Motoca"),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyApp()),
                    (Route<dynamic> route) => false);
              },
              child: const Icon(
                Icons.logout,
                color: Colors.white,
                size: 20.0,
              ),
            )
          ],
        ),
      ),
      body: const MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  String googleApiKey = "AIzaSyAhKKkgVrl2sqAG-rB8s-QbA4lS06hwAu4";

  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};

  bool rotaFeita = false;
  bool procurandoMotorista = false;
  bool corridaAtiva = false;
  bool disponivelNaCidade = true;
  String motocasDisponivel = "";

  late User usuarioLogado;

  final TextEditingController _controllerEnderecoOrigem =
      TextEditingController();
  final TextEditingController controllerTelefoneUsuario =
      TextEditingController();
  final TextEditingController controllerTroco = TextEditingController();
  final TextEditingController controllerMotivoCancelamento =
      TextEditingController();

  String dropdownValueFormaPagamento = 'Pix';

  var maskFormatter = MaskTextInputFormatter(
      mask: '+55 (##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  Endereco endereco = Endereco();

  double precoPorKm = 0;
  String precoCorrida = "0";
  String kmCorrida = "0";
  String corridaId = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await pegarKeys();
      buscarUsuario(context);
    });
  }

  pegarKeys() async {
    CollectionReference keys = FirebaseFirestore.instance.collection('Keys');
    var docs = await keys.get();
    if (docs.size > 0) {
      googleApiKey = docs.docs.first["googleApiKey"];
      return;
    }
  }

  buscarUsuario(context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        user.reload();

        usuarioLogado = user;
        var userId = usuarioLogado.uid;
        verificarSeTemCorrida(userId).then((corrida) {
          corridaEmAndamento(corrida);
        }).onError((error, stackTrace) {
          if (!mounted) {
            return;
          }
          atualizarLocalUsuario();
        });
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
            (Route<dynamic> route) => false);
      }
    });
  }

  pegarNumeroTelefoneUsuario() async {
    await Alert(
      context: context,
      title: "Bem vindo ao motoca",
      closeFunction: null,
      desc: "Precisamos de seu telefone para contato",
      onWillPopActive: false,
      content: TextField(
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [maskFormatter],
        style: const TextStyle(color: Colors.black),
        controller: controllerTelefoneUsuario,
        decoration: const InputDecoration(
          labelText: 'Digite logo a seguir:',
          hintText: '00 000000000',
          labelStyle: TextStyle(fontSize: 20.0, color: Colors.black),
          fillColor: Colors.black,
        ),
      ),
      style: const AlertStyle(backgroundColor: Colors.white),
      closeIcon: const SizedBox(),
      buttons: [
        DialogButton(
            color: Colors.green,
            child: const Text(
              "Salvar",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              if (controllerTelefoneUsuario.text.length < 19) {
                exibirToastTop("Telefone inválido");
              } else {
                await inserirTelefoneUsuario(
                    usuarioLogado, controllerTelefoneUsuario.text);
                Navigator.of(context, rootNavigator: true).pop();
                pegarEnderecoDestino();
              }
            })
      ],
    ).show();
  }

  corridaEmAndamento(dynamic corrida) async {
    setState(() {
      endereco = Endereco.fromJson(corrida['endereco']);
      precoCorrida = corrida["preco"].toString();
      kmCorrida = corrida["km"].toString();
      corridaId = corrida.id;
      adicionarMarker(endereco.latLongEnderecoOrigem.latitude,
          endereco.latLongEnderecoOrigem.longitude, "Sua localização");
      adicionarMarker(endereco.latLongEnderecoDestino.latitude,
          endereco.latLongEnderecoDestino.longitude, "Destino");
      calcularRota(
          endereco.latLongEnderecoOrigem.latitude,
          endereco.latLongEnderecoOrigem.longitude,
          endereco.latLongEnderecoDestino.latitude,
          endereco.latLongEnderecoDestino.longitude);
      atualizarCameraMapa(endereco.latLongEnderecoOrigem.latitude,
          endereco.latLongEnderecoOrigem.longitude);
      if (corrida["status"] == "procurando") {
        procurandoMotorista = true;
      } else {
        corridaAtiva = true;
      }
      adicionarListenerProcurandoMotorista();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: !procurandoMotorista && !corridaAtiva
            ? AppBar(
                title: Column(
                  children: [
                    TextField(
                      controller: _controllerEnderecoOrigem,
                      onTap: pegarEnderecoOrigem,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Digite o seu endereço (origem)',
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: Set<Marker>.of(markers.values),
        polylines: Set<Polyline>.of(polylines.values),
      ),
      persistentFooterButtons: [
        corridaAtiva
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                    ),
                    Row(
                      children: const [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'Seu motoca está a caminho',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    FloatingActionButton.extended(
                      onPressed: mostrarInfoMotoca,
                      label: const Text('Clique aqui para ver detalhes'),
                    ),
                  ],
                ),
              )
            : const SizedBox(),
        !corridaAtiva && procurandoMotorista
            ? Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "Km: " + kmCorrida,
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        "Valor: R\$ " + precoCorrida,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Procurando motorista"),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: FloatingActionButton.extended(
                          onPressed: () async {
                            exibirAlertaCancelarCorrida(context);
                          },
                          backgroundColor: Colors.red,
                          label: const Text(
                            'Cancelar corrida',
                            style: TextStyle(
                              color: Colors.white,
                              // fontSize: 10,
                            ),
                          ),
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                ],
              )
            : const SizedBox(),
      ],
      floatingActionButton: (!procurandoMotorista && !corridaAtiva) &&
              disponivelNaCidade &&
              motocasDisponivel == "aberta"
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                !rotaFeita
                    ? const SizedBox(
                        width: 20,
                      )
                    : const SizedBox(),
                !rotaFeita
                    ? FloatingActionButton.extended(
                        onPressed: pegarEnderecoDestino,
                        label: const Text('Solicitar Corrida'),
                        icon: const Icon(Icons.motorcycle),
                      )
                    : const SizedBox(),
                rotaFeita
                    ? FloatingActionButton.extended(
                        onPressed: () {
                          cancelarCorridaApp();
                        },
                        backgroundColor: Colors.red,
                        label: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.white),
                        ),
                        icon: const Icon(
                          Icons.cancel,
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox(),
                rotaFeita
                    ? const SizedBox(
                        width: 20,
                      )
                    : const SizedBox(),
                rotaFeita
                    ? FloatingActionButton.extended(
                        onPressed: () async {
                          await atualizarPrecoPorKm(endereco.cidade);
                          double distanciaEmMetros = Geolocator.distanceBetween(
                              endereco.latLongEnderecoOrigem.latitude,
                              endereco.latLongEnderecoOrigem.longitude,
                              endereco.latLongEnderecoDestino.latitude,
                              endereco.latLongEnderecoDestino.longitude);
                          double km = double.parse((distanciaEmMetros / 1000)
                              .toStringAsExponential(2));
                          var preco = double.parse(
                              (km * precoPorKm).toStringAsExponential(2));
                          validarDadosCorrida(context, preco, km,
                              title: "Detalhes da Corrida",
                              texto: "Preço R\$ " +
                                  preco.toString() +
                                  " \n Distancia: " +
                                  km.toString() +
                                  " Km");
                        },
                        label: const Text('Continuar'),
                        icon: const Icon(Icons.next_plan),
                      )
                    : const SizedBox(),
              ],
            )
          : motocasDisponivel == "fechado"
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      onPressed: () => {
                        exibirToastTop(
                            'Não tem motocas disponíveis \nnesse momento :('),
                      },
                      label: const Text(
                          'Não tem motocas disponíveis \nnesse momento :('),
                    )
                  ],
                )
              : !corridaAtiva && !procurandoMotorista
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton.extended(
                          onPressed: () => {
                            exibirToastTop('App indisponível em sua cidade :('),
                          },
                          label:
                              const Text('App indisponível em sua cidade :('),
                        )
                      ],
                    )
                  : const SizedBox(),
    );
  }

  void pegarEnderecoDestino() async {
    verificarSeTemUsuario(usuarioLogado.uid).then((user) async {
      if (endereco.latLongEnderecoOrigem.latitude == 0 &&
          endereco.latLongEnderecoOrigem.longitude == 0) {
        await atualizarLocalUsuario();
      }
      Prediction? p = await PlacesAutocomplete.show(
        context: context,
        apiKey: googleApiKey,
        mode: Mode.overlay, // Mode.fullscreen
        language: "pt",
        region: "pt-br",
        decoration: const InputDecoration(
          hintText: 'Digite o endereço de destino',
        ),
        components: [
          Component(Component.country, "br"),
        ],
        offset: 0,
        radius: 1000,
        strictbounds: false,
        types: [],
        sessionToken: "",
      );
      pegarLatLongDoEnderecoDestino(p);
    }).onError((error, stackTrace) {
      pegarNumeroTelefoneUsuario();
    });
  }

  void pegarEnderecoOrigem() async {
    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: googleApiKey,
      mode: Mode.overlay, // Mode.fullscreen
      language: "pt",
      region: "pt-br",
      decoration: const InputDecoration(
        hintText: 'Digite o endereço de origem',
      ),
      components: [
        Component(Component.country, "br"),
      ],
      offset: 0,
      radius: 1000,
      strictbounds: false,
      types: [],
      sessionToken: "",
    );
    if (p != null) {
      try {
        var endereco = await configurarEnderecoOrigem(p);
        _controllerEnderecoOrigem.text = endereco;
        cancelarCorridaApp();
      } catch (e) {
        exibirToastTop(e.toString());
      }
    }
  }

  Future<Null> pegarLatLongDoEnderecoDestino(Prediction? p) async {
    if (p != null) {
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: googleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      String placeId = p.placeId.toString();
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(placeId);
      final lat = detail.result.geometry?.location.lat;
      final lng = detail.result.geometry?.location.lng;
      adicionarMarker(double.parse(lat.toString()),
          double.parse(lng.toString()), "Destino");
      List<LatLng> latlng = [];
      markers.forEach((key, value) {
        latlng.add(LatLng(value.position.latitude, value.position.longitude));
      });

      await atualizarCameraMapa(latlng.last.latitude, latlng.last.longitude);
      endereco.latLongEnderecoDestino =
          LatLng(latlng.last.latitude, latlng.last.longitude);
      endereco.enderecoDestino = detail.result.vicinity.toString();
      polylines = <PolylineId, Polyline>{};
      await calcularRota(latlng.first.latitude, latlng.first.longitude,
          latlng.last.latitude, latlng.last.longitude);
    }
  }

  Future<String> configurarEnderecoOrigem(Prediction? p) async {
    if (p != null) {
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: googleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      String placeId = p.placeId.toString();
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(placeId);
      final lat = detail.result.geometry?.location.lat;
      final long = detail.result.geometry?.location.lng;
      adicionarMarker(double.parse(lat.toString()),
          double.parse(long.toString()), "Sua localização");
      atualizarCameraMapa(
          double.parse(lat.toString()), double.parse(long.toString()));
      String cidade = "";
      try {
        cidade = detail.result.addressComponents
            .where((componentsEndereco) =>
                componentsEndereco.types.first ==
                    "administrative_area_level_2" ||
                componentsEndereco.types.last == "administrative_area_level_2")
            .first
            .longName;
        if (cidade == "") {
          exibirToastTop("Não conseguimos identificar sua cidade");
          return Future.error("Não conseguimos identificar sua cidade");
        }
        await atualizarPrecoPorKm(cidade);
        await setarEnderecoOrigem(double.parse(lat.toString()),
            double.parse(long.toString()), cidade);
        return endereco.enderecoOrigem;
      } catch (e) {
        return Future.error("Erro ao pegar endereço");
      }
    } else {
      return Future.error("Erro ao pegar endereço");
    }
  }

  calcularRota(
    double startLatitude,
    double startLongitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(startLatitude, startLongitude),
      PointLatLng(destinationLatitude, destinationLongitude),
    );

    polylineCoordinates = [];

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    PolylineId id = const PolylineId('poly');

    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 5,
    );

    setState(() {
      polylines.remove('poly');
      polylines[id] = polyline;
    });

    rotaFeita = true;
  }

  Future<void> validarDadosCorrida(context, double preco, double km,
      {String title = "", String texto = ""}) async {
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                title,
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              content: SizedBox(
                height: dropdownValueFormaPagamento == "Dinheiro" ? 249 : 183,
                child: Column(
                  children: [
                    const Text(
                      "Selecione a forma de pagamento",
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          value: dropdownValueFormaPagamento,
                          icon: const Icon(
                            Icons.arrow_downward,
                            color: Colors.black,
                          ),
                          elevation: 16,
                          style: const TextStyle(color: Colors.black),
                          underline: Container(
                            height: 2,
                            color: Colors.black,
                          ),
                          dropdownColor: Colors.white,
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownValueFormaPagamento = newValue!;
                            });
                          },
                          items: <String>['Pix', 'Cartão', 'Dinheiro']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    dropdownValueFormaPagamento == "Dinheiro"
                        ? TextField(
                            style: const TextStyle(color: Colors.black),
                            autofocus: true,
                            controller: controllerTroco,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              focusColor: Colors.black,
                              labelText: 'Digite o troco',
                              labelStyle: TextStyle(
                                  fontSize: 20.0, color: Colors.black),
                            ),
                          )
                        : const SizedBox(),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          "Km: " + km.toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          "Valor: R\$ " + preco.toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: DialogButton(
                            color: Colors.red,
                            child: const Text(
                              "Cancelar",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                          ),
                        ),
                        Expanded(
                          child: DialogButton(
                            color: Colors.green,
                            child: const Text(
                              "Confirmar",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              procurandoMotorista = true;
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
        }).then((value) async {
      if (procurandoMotorista) {
        if (!disponivelNaCidade) {
          exibirToastTop("App indisponível na cidade :(");
          return;
        }
        await inserirCorrida(usuarioLogado, preco, km, endereco,
                dropdownValueFormaPagamento, controllerTroco.text)
            .then((value) {
          exibirToastTop("Estamos procurando um motorista");
          setState(() {
            precoCorrida = preco.toString();
            kmCorrida = km.toString();
            procurandoMotorista = true;
            corridaId = value.id;
          });
          adicionarListenerProcurandoMotorista();
        });
      }
    });
  }

  Future adicionarListenerProcurandoMotorista() async {
    String userId = usuarioLogado.uid;
    FirebaseFirestore.instance
        .collection('Corridas')
        .where('userId', isEqualTo: userId)
        .where("status", whereIn: ["procurando", "aceito"])
        .snapshots()
        .listen((event) async {
          for (var element in event.docChanges) {
            var statusCorridaAtual = await buscarStatusCorridaPorId(
                usuarioLogado.uid, element.doc.id);
            if (statusCorridaAtual == "aceito") {
              setState(() {
                corridaAtiva = true;
              });
            }
            if (statusCorridaAtual == "cancelado") {
              setState(() {
                corridaAtiva = false;
              });
              corridaCancelada();
            }
            if (statusCorridaAtual == "finalizado") {
              setState(() {
                corridaAtiva = false;
              });
              corridaFinalizada();
            }
          }
        });
  }

  // Future adicionarListenerAceitoMotorista(id) async {
  //   String userId = usuarioLogado.uid;
  //   FirebaseFirestore.instance
  //       .collection('Corridas')
  //       .where('userId', isEqualTo: userId)
  //       .where("status", whereIn: ["finalizado", "cancelado"])
  //       .snapshots()
  //       .listen((event) {
  //         for (var element in event.docChanges) {
  //           var status = element.doc.get("status");

  //         }
  //       });
  // }

  corridaFinalizada() async {
    await Alert(
      context: context,
      title: "Corrida finalizada",
      desc: "Obrigado por utilizar nosso serviço :')",
      style: const AlertStyle(backgroundColor: Colors.white),
      buttons: [
        DialogButton(
          color: Colors.green,
          child: const Text(
            "Demais!",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () async {
            cancelarCorridaApp();
            Navigator.of(context, rootNavigator: true).pop();
          },
        )
      ],
    ).show();
  }

  corridaCancelada() async {
    await Alert(
      context: context,
      title: "Corrida cancelada",
      desc: "Infelizmente foi cancelado sua corrida",
      style: const AlertStyle(backgroundColor: Colors.white),
      buttons: [
        DialogButton(
          color: Colors.green,
          child: const Text(
            "Que pena :(",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () async {
            cancelarCorridaApp();
            Navigator.of(context, rootNavigator: true).pop();
          },
        )
      ],
    ).show();
  }

  Future<void> atualizarLocalUsuario() async {
    try {
      var position = await pegarLocalizacao();
      await atualizarCameraMapa(position.latitude, position.longitude);

      markers = <MarkerId, Marker>{};
      adicionarMarker(position.latitude, position.longitude, "Sua localização");
      var place =
          await latlongParaEndereco(position.latitude, position.longitude);
      _controllerEnderecoOrigem.text = place.street.toString() +
          " " +
          place.subThoroughfare.toString() +
          " " +
          place.subLocality.toString();
      await setarEnderecoOrigem(position.latitude, position.longitude,
          place.subAdministrativeArea.toString());
    } catch (e) {
      exibirToastTop(e.toString());
      pegarEnderecoOrigem();
    }
  }

  void adicionarMarker(double lat, double long, String markerIdVal) {
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
        lat,
        long,
      ),
      infoWindow: InfoWindow(title: markerIdVal, snippet: ''),
      onTap: () {},
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  void configuracaoCorrida(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: new Icon(Icons.music_note),
                    title: new Text('Músicas'),
                    onTap: () => {}),
                ListTile(
                  leading: new Icon(Icons.videocam),
                  title: new Text('Videos'),
                  onTap: () => {},
                ),
                ListTile(
                  leading: new Icon(Icons.satellite),
                  title: new Text('Tempo'),
                  onTap: () => {},
                ),
              ],
            ),
          );
        });
  }

  setarEnderecoOrigem(double latitude, double longitude, String cidade) async {
    endereco.latLongEnderecoOrigem = LatLng(latitude, longitude);
    var place = await latlongParaEndereco(latitude, longitude);
    endereco.enderecoOrigem = place.street.toString() +
        ", " +
        place.subThoroughfare.toString() +
        " - " +
        place.subLocality.toString() +
        ', ' +
        cidade;
    endereco.cidade = cidade;
    await atualizarPrecoPorKm(cidade);
  }

  atualizarCameraMapa(double lat, double long) async {
    CameraPosition cameraLocalUsuario =
        CameraPosition(target: LatLng(lat, long), zoom: 15, bearing: 10);

    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(cameraLocalUsuario));
  }

  cancelarCorridaApp() {
    setState(() {
      polylineCoordinates = [];
      polylines = {};
      markers.removeWhere((key, value) => value.markerId.value == "Destino");
      endereco.enderecoDestino = "";
      endereco.latLongEnderecoDestino = const LatLng(0, 0);
      rotaFeita = false;
      procurandoMotorista = false;
      corridaAtiva = false;
      atualizarCameraMapa(endereco.latLongEnderecoOrigem.latitude,
          endereco.latLongEnderecoOrigem.longitude);
      _controllerEnderecoOrigem.text = endereco.enderecoOrigem;
    });
  }

  Future<void> exibirAlertaCancelarCorrida(context) async {
    await Alert(
      context: context,
      title: "Deseja realmente cancelar a corrida?",
      content: TextField(
        style: const TextStyle(color: Colors.black),
        autofocus: true,
        controller: controllerMotivoCancelamento,
        decoration: const InputDecoration(
          focusColor: Colors.black,
          labelText: 'Digite o motivo do cancelamento',
          labelStyle: TextStyle(fontSize: 20.0, color: Colors.black),
          fillColor: Colors.black,
        ),
      ),
      style: const AlertStyle(backgroundColor: Colors.white),
      buttons: [
        DialogButton(
          color: Colors.red,
          child: const Text(
            "Não",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
        DialogButton(
          color: Colors.green,
          child: const Text(
            "Sim",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () async {
            if (controllerMotivoCancelamento.text.trim() == "") {
              exibirToastTop("Digite o motivo do cancelamento");
              return;
            }
            try {
              await cancelarCorrida(
                  corridaId, controllerMotivoCancelamento.text);

              exibirToastTop("Corrida cancelada com sucesso");

              controllerMotivoCancelamento.text = "";
              Navigator.of(context, rootNavigator: true).pop();
              cancelarCorridaApp();
            } catch (e) {
              exibirToastTop("Erro ao cancelar corrida");
            }
          },
        )
      ],
    ).show();
  }

  mostrarInfoMotoca() async {
    buscarCorridaAtual(usuarioLogado.uid).then((c) async {
      await Alert(
        context: context,
        title: "Informações do motoca",
        desc: c["motoca"]["nomeCompleto"] +
            " \n Telefone: " +
            c["motoca"]["telefone"] +
            " \n Moto: " +
            c["motoca"]["moto"] +
            " \n Placa: " +
            c["motoca"]["placa"] +
            " \n \n" +
            "Seu motoca chega até: \n" +
            c["tempoDestino"],
        style: const AlertStyle(backgroundColor: Colors.white),
        buttons: [
          DialogButton(
            color: Colors.red,
            child: const Text(
              "Ok",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          ),
        ],
      ).show();
    });
  }

  atualizarPrecoPorKm(cidade) async {
    await buscarConfiguracaoCidade(cidade).then((value) {
      precoPorKm = double.parse(value["precoPorKm"].toString());
      setState(() {
        motocasDisponivel = value["status"];
        disponivelNaCidade = true;
      });
    }).onError((error, stackTrace) {
      setState(() {
        motocasDisponivel = "";
        disponivelNaCidade = false;
      });
      exibirToastTop("App App indisponível em sua cidade");
    });
  }
}
