import 'package:Motoca/Cliente/NavDrawer.dart';
import 'package:Motoca/Cliente/Singletons/Singletons_nav.dart';
import 'package:Motoca/Cliente/Singletons/corrida_singleton.dart';
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
      drawer: const NavDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Motoca"),
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
  State<MapSample> createState() => InicioClientState();
}

class InicioClientState extends State<MapSample> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  LatLng posicaoCameraAtual = const LatLng(0, 0);

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  String googleApiKey = "AIzaSyAhKKkgVrl2sqAG-rB8s-QbA4lS06hwAu4";
  String tempoMinimoEmMinutosParaCancelarCorrida = "0";

  late PolylinePoints polylinePoints;
  List<LatLng> polylineCoordinates = [];
  Map<PolylineId, Polyline> polylines = {};

  bool rotaFeita = false;
  bool procurandoMotorista = false;
  bool corridaAndamento = false;
  bool corridaAceita = false;
  bool disponivelNaCidade = true;
  bool pegandoEnderecoDestino = false;
  String statusCidade = "";

  dynamic corridaAtual;
  String tempoEmMinutosAteOMotocaChegar = "";

  bool usuarioQuerDigitarMotivoCancelamento = false;

  late User usuarioLogado;

  final TextEditingController _controllerEnderecoOrigem =
      TextEditingController();
  final TextEditingController _controllerEnderecoDestino =
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
    SingletonNav.instance.setContext(context);
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
      tempoMinimoEmMinutosParaCancelarCorrida =
          docs.docs.first["tempoMinimoMinutosParaCancelar"];
      SingletonCorrida.instance.setTempoMinimoMinutoParaCancelarCorrida(
          tempoMinimoEmMinutosParaCancelarCorrida);
      return;
    }
  }

  buscarUsuario(context) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        user.reload();
        usuarioLogado = user;
        var userId = usuarioLogado.uid;
        SingletonCorrida.instance.setUsuarioId(userId);
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
          labelText: 'Digite a seguir:',
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
      corridaAtual = corrida;
      corridaId = corrida.id;
      SingletonCorrida.instance.setCorridaId(corridaId);
      adicionarMarker(endereco.latLongEnderecoOrigem.latitude,
          endereco.latLongEnderecoOrigem.longitude, "Sua localização");
      adicionarMarker(endereco.latLongEnderecoDestino.latitude,
          endereco.latLongEnderecoDestino.longitude, "Destino");
      _controllerEnderecoOrigem.text = endereco.enderecoOrigem;
      _controllerEnderecoDestino.text = endereco.enderecoDestino;
      calcularRota(
          endereco.latLongEnderecoOrigem.latitude,
          endereco.latLongEnderecoOrigem.longitude,
          endereco.latLongEnderecoDestino.latitude,
          endereco.latLongEnderecoDestino.longitude);
      atualizarCameraMapa(endereco.latLongEnderecoOrigem.latitude,
          endereco.latLongEnderecoOrigem.longitude);
      if (corrida["status"] == "procurando") {
        procurandoMotorista = true;
      } else if (corrida["status"] == "andamento") {
        corridaAndamento = true;
      } else if (corrida["status"] == "aceito") {
        corridaAceita = true;
        buscarTempoQueMotocaChegaEmMinutos();
      }
      SingletonCorrida.instance.setCorridaAtiva(true);
      adicionarListenerProcurandoMotorista();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Origem:"),
                TextField(
                  controller: _controllerEnderecoOrigem,
                  onTap: () {
                    verificarComoUsuarioQuerEscolherLocalizacao("origem");
                  },
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Digite o seu endereço (origem)',
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const Text("Destino:"),
                TextField(
                  controller: _controllerEnderecoDestino,
                  onTap: () {
                    verificarComoUsuarioQuerEscolherLocalizacao("destino");
                  },
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Digite o seu endereço (destino)',
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 160),
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: Set<Marker>.of(markers.values),
              onCameraMove: ((_position) => updateCameraPosition(_position)),
              onCameraIdle: () => {updateMarkerCamera()},
              polylines: Set<Polyline>.of(polylines.values),
            ),
          ),
        ],
      ),
      persistentFooterButtons: [
        corridaAceita
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    corridaAtual != null
                        ? Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Preço: R\$" + corridaAtual["preco"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  tempoEmMinutosAteOMotocaChegar != "0"
                                      ? Text(
                                          "Motoca vai chegar em: " +
                                              tempoEmMinutosAteOMotocaChegar +
                                              " minutos",
                                          style: const TextStyle(fontSize: 18),
                                        )
                                      : const SizedBox(),
                                  const Divider(
                                    color: Colors.white,
                                  ),
                                  Text(
                                    "Nome: " +
                                        (corridaAtual["motoca"]["nomeCompleto"])
                                            .toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    "Moto: " +
                                        (corridaAtual["motoca"]["motos"]
                                                    .where((m) =>
                                                        m["status"] == "ativa")
                                                    .first["marca"] +
                                                " " +
                                                corridaAtual["motoca"]["motos"]
                                                    .where((m) =>
                                                        m["status"] == "ativa")
                                                    .first["ano"] +
                                                " - " +
                                                corridaAtual["motoca"]["motos"]
                                                    .where((m) =>
                                                        m["status"] == "ativa")
                                                    .first["cor"])
                                            .toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    "Placa: " +
                                        (corridaAtual["motoca"]["motos"]
                                                .where((m) =>
                                                    m["status"] == "ativa")
                                                .first["placa"])
                                            .toString(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox(),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                            child: validarBotaoCancelarCorrida()
                                ? FloatingActionButton.extended(
                                    onPressed: () async {
                                      setState(() {
                                        usuarioQuerDigitarMotivoCancelamento =
                                            false;
                                      });
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
                                  )
                                : FloatingActionButton.extended(
                                    onPressed: () async {},
                                    backgroundColor: Colors.grey,
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
                                  )),
                      ],
                    )
                  ],
                ),
              )
            : corridaAndamento
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 40,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Corrida em andamento',
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        corridaAtual != null
                            ? Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Preço: R\$" + corridaAtual["preco"],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Divider(
                                        height: 5,
                                        color: Colors.white,
                                      ),
                                      Text(
                                        "Nome: " +
                                            (corridaAtual["motoca"]
                                                    ["nomeCompleto"])
                                                .toString(),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      Text(
                                        "Moto: " +
                                            (corridaAtual["motoca"]["motos"]
                                                        .where((m) =>
                                                            m["status"] ==
                                                            "ativa")
                                                        .first["marca"] +
                                                    " " +
                                                    corridaAtual["motoca"]
                                                            ["motos"]
                                                        .where((m) =>
                                                            m["status"] ==
                                                            "ativa")
                                                        .first["ano"] +
                                                    " - " +
                                                    corridaAtual["motoca"]
                                                            ["motos"]
                                                        .where((m) =>
                                                            m["status"] ==
                                                            "ativa")
                                                        .first["cor"])
                                                .toString(),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      Text(
                                        "Placa: " +
                                            (corridaAtual["motoca"]["motos"]
                                                    .where((m) =>
                                                        m["status"] == "ativa")
                                                    .first["placa"])
                                                .toString(),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        // const SizedBox(
                        //   height: 20,
                        // ),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Expanded(
                        //       child: FloatingActionButton.extended(
                        //         onPressed: () async {
                        //           setState(() {
                        //             usuarioQuerDigitarMotivoCancelamento =
                        //                 false;
                        //           });
                        //           exibirAlertaCancelarCorrida(context);
                        //         },
                        //         backgroundColor: Colors.red,
                        //         label: const Text(
                        //           'Cancelar corrida',
                        //           style: TextStyle(
                        //             color: Colors.white,
                        //             // fontSize: 10,
                        //           ),
                        //         ),
                        //         icon: const Icon(
                        //           Icons.cancel,
                        //           color: Colors.white,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // )
                      ],
                    ),
                  )
                : const SizedBox(),
        !corridaAceita && !corridaAndamento && procurandoMotorista
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
                            try {
                              await cancelarCorrida(
                                  "Cancelado procurando motorista");

                              exibirToastTop("Corrida cancelada com sucesso");
                              cancelarCorridaApp();
                            } catch (e) {
                              exibirToastTop(e.toString());
                            }
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
      floatingActionButton: (!procurandoMotorista &&
                  !corridaAceita &&
                  !corridaAndamento) &&
              disponivelNaCidade &&
              statusCidade == "aberta"
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
                        backgroundColor: Colors.greenAccent,
                        onPressed: () {
                          verificarComoUsuarioQuerEscolherLocalizacao(
                              "destino");
                        },
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
                        backgroundColor: Colors.greenAccent,
                        icon: const Icon(Icons.next_plan),
                      )
                    : const SizedBox(),
              ],
            )
          : statusCidade == "fechado"
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      backgroundColor: Colors.greenAccent,
                      onPressed: () => {
                        exibirToastTop('App indisponível em sua cidade :('),
                      },
                      label: const Text('App indisponível em sua cidade :('),
                    )
                  ],
                )
              : !corridaAceita && !procurandoMotorista && !corridaAndamento
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton.extended(
                          backgroundColor: Colors.greenAccent,
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

  verificarComoUsuarioQuerEscolherLocalizacao(tipoLocalizacao) async {
    if (!corridaAceita && !corridaAndamento && !procurandoMotorista) {
      await Alert(
        context: context,
        title: "Como deseja preencher o local?",
        style: const AlertStyle(backgroundColor: Colors.white),
        buttons: [
          DialogButton(
            color: Colors.greenAccent,
            child: const Text(
              "Pelo Mapa",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (tipoLocalizacao == "origem") {
                pegandoEnderecoDestino = false;
                if (endereco.latLongEnderecoOrigem.latitude != 0 &&
                    endereco.latLongEnderecoOrigem.longitude != 0) {
                  atualizarCameraMapa(endereco.latLongEnderecoOrigem.latitude,
                      endereco.latLongEnderecoOrigem.longitude);
                }
              } else if (tipoLocalizacao == "destino") {
                pegandoEnderecoDestino = true;
                if (endereco.latLongEnderecoDestino.latitude != 0 &&
                    endereco.latLongEnderecoDestino.longitude != 0) {
                  atualizarCameraMapa(endereco.latLongEnderecoDestino.latitude,
                      endereco.latLongEnderecoDestino.longitude);
                }
              }
            },
          ),
          DialogButton(
            color: Colors.greenAccent,
            child: const Text(
              "Digitando",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              if (tipoLocalizacao == "origem") {
                pegarEnderecoOrigem();
              } else if (tipoLocalizacao == "destino") {
                pegarEnderecoDestino();
              }
            },
          ),
        ],
      ).show();
    }
  }

  updateCameraPosition(CameraPosition _position) async {
    if (!procurandoMotorista && !corridaAceita && !corridaAndamento) {
      posicaoCameraAtual =
          LatLng(_position.target.latitude, _position.target.longitude);

      MarkerId markerId =
          MarkerId(!pegandoEnderecoDestino ? "Sua localização" : "Destino");
      if (markers.length == 2) {
        Marker? marker = markers[markerId];
        if (marker != null) {
          Marker updatedMarker = marker.copyWith(
            positionParam: _position.target,
          );

          setState(() {
            markers[markerId] = updatedMarker;
          });
        }
      } else {
        adicionarMarker(_position.target.latitude, _position.target.longitude,
            !pegandoEnderecoDestino ? "Sua localização" : "Destino");
      }
    }
  }

  updateMarkerCamera() async {
    if (!procurandoMotorista && !corridaAceita && !corridaAndamento) {
      try {
        if (posicaoCameraAtual.latitude != 0 &&
            posicaoCameraAtual.longitude != 0) {
          if (!pegandoEnderecoDestino) {
            await setarEnderecoOrigem(
                posicaoCameraAtual.latitude, posicaoCameraAtual.longitude);
          } else {
            await setarEnderecoDestino(
                posicaoCameraAtual.latitude, posicaoCameraAtual.longitude);
          }
          await updateCameraPosition(CameraPosition(
              target: LatLng(
                  posicaoCameraAtual.latitude, posicaoCameraAtual.longitude)));
        }
      } catch (e) {
        return Future.error("Erro ao pegar endereço");
      }
    }
  }

  void pegarEnderecoDestino() async {
    if (!procurandoMotorista && !corridaAceita && !corridaAndamento) {
      verificarSeTemUsuario(usuarioLogado.uid).then((user) async {
        if (endereco.latLongEnderecoOrigem.latitude == 0 &&
            endereco.latLongEnderecoOrigem.longitude == 0) {
          await atualizarLocalUsuario();
        }
        setState(() {
          pegandoEnderecoDestino = true;
        });
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
          startText: _controllerEnderecoDestino.text.toString().toLowerCase(),
          offset: 0,
          radius: 1000,
          strictbounds: false,
          location: Location(
              lat: endereco.latLongEnderecoOrigem.latitude,
              lng: endereco.latLongEnderecoOrigem.longitude),
          types: [],
          sessionToken: "",
        );
        pegarLatLongDoEnderecoDestino(p);
      }).onError((error, stackTrace) {
        pegarNumeroTelefoneUsuario();
      });
    }
  }

  void pegarEnderecoOrigem() async {
    if (!procurandoMotorista && !corridaAceita && !corridaAndamento) {
      Prediction? p;
      try {
        var position = await pegarLocalizacao();
        p = await PlacesAutocomplete.show(
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
          startText: _controllerEnderecoOrigem.text.toString().toLowerCase(),
          location: Location(lat: position.latitude, lng: position.longitude),
          types: [],
          sessionToken: "",
        );
      } catch (e) {
        p = await PlacesAutocomplete.show(
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
          startText: _controllerEnderecoOrigem.text.toString(),
          types: [],
          sessionToken: "",
        );
      }

      if (p != null) {
        try {
          await configurarEnderecoOrigem(p);
        } catch (e) {
          exibirToastTop(e.toString());
        }
      }
    }
  }

  Future pegarLatLongDoEnderecoDestino(Prediction? p) async {
    if (p != null) {
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: googleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      String placeId = p.placeId.toString();
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(placeId);
      final lat = detail.result.geometry?.location.lat;
      final lng = detail.result.geometry?.location.lng;
      await atualizarCameraMapa(
          double.parse(lat.toString()), double.parse(lng.toString()));
    }
  }

  Future configurarEnderecoOrigem(Prediction? p) async {
    if (p != null) {
      pegandoEnderecoDestino = false;
      GoogleMapsPlaces _places = GoogleMapsPlaces(
        apiKey: googleApiKey,
        apiHeaders: await const GoogleApiHeaders().getHeaders(),
      );
      String placeId = p.placeId.toString();
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(placeId);
      final lat = detail.result.geometry?.location.lat;
      final long = detail.result.geometry?.location.lng;
      await atualizarCameraMapa(
          double.parse(lat.toString()), double.parse(long.toString()));
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
                              SingletonCorrida.instance.setCorridaAtiva(true);
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
          procurandoMotorista = false;
          return;
        }
        if (controllerTroco.text != "" &&
            double.parse(controllerTroco.text) < 0 &&
            dropdownValueFormaPagamento == "Dinheiro") {
          exibirToastTop("Troco inválido");
          procurandoMotorista = false;
          return;
        }
        try {
          await inserirCorrida(usuarioLogado, preco, km, endereco,
                  dropdownValueFormaPagamento, controllerTroco.text)
              .then((value) {
            exibirToastTop("Estamos procurando um motorista");
            setState(() {
              precoCorrida = preco.toString();
              kmCorrida = km.toString();
              procurandoMotorista = true;
              corridaId = value.id;
              SingletonCorrida.instance.setCorridaId(corridaId);
            });
            adicionarListenerProcurandoMotorista();
          });
        } catch (e) {
          procurandoMotorista = false;
          exibirToastTop(e.toString());
        }
      }
    });
  }

  Future adicionarListenerProcurandoMotorista() async {
    String userId = usuarioLogado.uid;
    FirebaseFirestore.instance
        .collection('Corridas')
        .where('userId', isEqualTo: userId)
        .where("status", whereIn: ["procurando", "aceito", "andamento"])
        .snapshots()
        .listen((event) async {
          for (var element in event.docChanges) {
            var corrida = await buscarCorridaPorId(element.doc.id);
            var statusCorridaAtual = corrida.get("status");
            var canceladoPeloAdm = false;
            try {
              canceladoPeloAdm = corrida.get("cancelamentoAdministrativo");
            } catch (e) {}

            if (statusCorridaAtual == "aceito") {
              setState(() {
                corridaAtual = corrida;
                corridaAceita = true;
                SingletonCorrida.instance.setCorridaAtiva(true);
              });
              buscarTempoQueMotocaChegaEmMinutos();
            }
            if (statusCorridaAtual == "cancelado" && corridaAceita) {
              setState(() {
                corridaAtual = null;
                corridaAceita = false;
                procurandoMotorista = false;
                SingletonCorrida.instance.setCorridaAtiva(false);
              });
              if (canceladoPeloAdm) {
                await corridaCancelada(corrida.get("motivoCancelamento"));
              } else {
                await corridaCancelada("");
              }
            }
            if (statusCorridaAtual == "cancelado" && procurandoMotorista) {
              setState(() {
                corridaAtual = null;
                procurandoMotorista = false;
                corridaAceita = false;
                SingletonCorrida.instance.setCorridaAtiva(false);
              });
              if (canceladoPeloAdm) {
                await corridaCancelada(corrida.get("motivoCancelamento"));
              }
            }
            if (statusCorridaAtual == "andamento") {
              setState(() {
                corridaAtual = corrida;
                corridaAceita = false;
                procurandoMotorista = false;
                corridaAndamento = true;
                SingletonCorrida.instance.setCorridaAtiva(true);
              });
            }
            if (statusCorridaAtual == "finalizado" && corridaAndamento) {
              setState(() {
                corridaAtual = null;
                corridaAndamento = false;
                SingletonCorrida.instance.setCorridaAtiva(false);
              });
              corridaFinalizada();
            }
          }
        });
  }

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
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            cancelarCorridaApp();
          },
        )
      ],
    ).show();
  }

  corridaCancelada(String motivoCancelamento) async {
    await Alert(
      context: context,
      title: "Sua corrida foi cancelada",
      desc: motivoCancelamento,
      style: const AlertStyle(backgroundColor: Colors.white),
      buttons: [
        DialogButton(
          color: Colors.green,
          child: const Text(
            "Ok",
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
    } catch (e) {
      if (endereco.latLongEnderecoOrigem.latitude != 0 &&
          endereco.latLongEnderecoOrigem.longitude != 0 &&
          endereco.enderecoOrigem != "") {
        await atualizarCameraMapa(endereco.latLongEnderecoOrigem.latitude,
            endereco.latLongEnderecoOrigem.longitude);
      } else {
        exibirToastTop(e.toString());
        pegarEnderecoOrigem();
      }
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
      infoWindow: InfoWindow(title: markerIdVal),
    );

    setState(() {
      if (markerIdVal == "Sua localização") {
        markers = <MarkerId, Marker>{};
      }
      markers[markerId] = marker;
    });
  }

  setarEnderecoOrigem(double latitude, double longitude) async {
    endereco.latLongEnderecoOrigem = LatLng(latitude, longitude);
    var enderecoOrigem =
        await latlongParaEndereco(latitude, longitude, googleApiKey);
    endereco.cidade = enderecoOrigem.cidade;
    await atualizarPrecoPorKm(enderecoOrigem.cidade);
    endereco.enderecoOrigem = enderecoOrigem.enderecoFormatado;
    setState(() {
      _controllerEnderecoOrigem.text = enderecoOrigem.enderecoFormatado;
    });
    if (endereco.latLongEnderecoDestino.latitude != 0 &&
        endereco.latLongEnderecoDestino.longitude != 0) {
      await calcularRota(
        latitude,
        longitude,
        endereco.latLongEnderecoDestino.latitude,
        endereco.latLongEnderecoDestino.longitude,
      );
    }
  }

  setarEnderecoDestino(double latitude, double longitude) async {
    endereco.latLongEnderecoDestino = LatLng(latitude, longitude);
    var enderecoDestino =
        await latlongParaEndereco(latitude, longitude, googleApiKey);
    await atualizarPrecoPorKm(endereco.cidade);
    endereco.enderecoDestino = enderecoDestino.enderecoFormatado;
    endereco.latLongEnderecoDestino = LatLng(latitude, longitude);
    await calcularRota(endereco.latLongEnderecoOrigem.latitude,
        endereco.latLongEnderecoOrigem.longitude, latitude, longitude);
    setState(() {
      _controllerEnderecoDestino.text = enderecoDestino.enderecoFormatado;
    });
  }

  atualizarCameraMapa(double lat, double long) async {
    if (lat != 0 && long != 0) {
      CameraPosition cameraLocalUsuario =
          CameraPosition(target: LatLng(lat, long), zoom: 15, bearing: 10);

      final GoogleMapController controller = await _controller.future;
      await controller
          .moveCamera(CameraUpdate.newCameraPosition(cameraLocalUsuario));

      posicaoCameraAtual = LatLng(lat, long);
    }
  }

  cancelarCorridaApp() async {
    setState(() {
      polylineCoordinates = [];
      polylines = {};
      markers.removeWhere((key, value) => value.markerId.value == "Destino");
      endereco.enderecoDestino = "";
      endereco.latLongEnderecoDestino = const LatLng(0, 0);
      rotaFeita = false;
      procurandoMotorista = false;
      corridaAndamento = false;
      corridaAceita = false;
      SingletonCorrida.instance.setCorridaAtiva(false);
      pegandoEnderecoDestino = false;
      _controllerEnderecoOrigem.text = endereco.enderecoOrigem;
      _controllerEnderecoDestino.text = "";
      controllerTroco.text = "";
      controllerMotivoCancelamento.text = "";
      endereco.enderecoDestino = "";
      endereco.latLongEnderecoDestino = const LatLng(0, 0);
      controllerMotivoCancelamento.text = "";
    });
    await atualizarLocalUsuario();
  }

  Future<void> exibirAlertaCancelarCorrida(context) async {
    await Alert(
      context: context,
      title: !usuarioQuerDigitarMotivoCancelamento
          ? "Escolha o motivo de cancelamento"
          : "Digite o motivo do cancelamento",
      content: Column(
        children: [
          !usuarioQuerDigitarMotivoCancelamento
              ? Column(
                  children: [
                    DialogButton(
                      color: Colors.greenAccent,
                      child: const Text(
                        "Tempo de espera",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context, rootNavigator: true).pop();
                        controllerMotivoCancelamento.text = "Tempo de espera";
                        try {
                          await cancelarCorrida(
                              controllerMotivoCancelamento.text);
                          cancelarCorridaApp();
                        } catch (e) {
                          exibirToastTop(e.toString());
                        }
                      },
                    ),
                    DialogButton(
                      color: Colors.greenAccent,
                      child: const Text(
                        "Não desejo mais fazer a corrida",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(context, rootNavigator: true).pop();
                        controllerMotivoCancelamento.text =
                            "Não desejo mais fazer a corrida";
                        try {
                          await cancelarCorrida(
                              controllerMotivoCancelamento.text);
                          cancelarCorridaApp();
                        } catch (e) {
                          exibirToastTop(e.toString());
                        }
                      },
                    ),
                    DialogButton(
                      color: Colors.greenAccent,
                      child: const Text(
                        "Outros",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          usuarioQuerDigitarMotivoCancelamento = true;
                        });
                        Navigator.of(context, rootNavigator: true).pop();
                        exibirAlertaCancelarCorrida(context);
                      },
                    ),
                  ],
                )
              : const SizedBox(),
          usuarioQuerDigitarMotivoCancelamento
              ? TextField(
                  style: const TextStyle(color: Colors.black),
                  autofocus: true,
                  controller: controllerMotivoCancelamento,
                  decoration: const InputDecoration(
                    focusColor: Colors.black,
                    labelText: 'Digite o motivo do cancelamento',
                    labelStyle: TextStyle(fontSize: 20.0, color: Colors.black),
                    fillColor: Colors.black,
                  ),
                )
              : const SizedBox(),
        ],
      ),
      style: const AlertStyle(backgroundColor: Colors.white),
      buttons: usuarioQuerDigitarMotivoCancelamento
          ? [
              DialogButton(
                color: Colors.red,
                child: const Text(
                  "Sair",
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
                  "Confirmar",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (controllerMotivoCancelamento.text.trim() == "") {
                    exibirToastTop("Digite o motivo do cancelamento");
                    return;
                  }
                  try {
                    await cancelarCorrida(controllerMotivoCancelamento.text);
                    cancelarCorridaApp();
                  } catch (e) {
                    exibirToastTop(e.toString());
                  }
                },
              )
            ]
          : [],
    ).show();
  }

  atualizarPrecoPorKm(cidade) async {
    // var temMotocaDisponivelNaCidade =
    //     await verificarMotocaDisponivelNaCidade(cidade);
    var temMotocaDisponivelNaCidade = true;
    await buscarConfiguracaoCidade(cidade).then((value) {
      setState(() {
        precoPorKm = double.parse(value["precoPorKm"].toString());
        statusCidade = value["status"];
        disponivelNaCidade = temMotocaDisponivelNaCidade;
      });
    }).onError((error, stackTrace) {
      setState(() {
        statusCidade = "";
        disponivelNaCidade = false;
      });
      exibirToastTop("App indisponível em sua cidade");
    });
  }

  buscarTempoQueMotocaChegaEmMinutos() {
    if (corridaAceita && corridaAtual != null) {
      var dataMotocaChega = DateTime.fromMicrosecondsSinceEpoch(
          corridaAtual["tempoDestino"].millisecondsSinceEpoch * 1000);
      var dataAtual = DateTime.now();

      if (dataAtual.isAfter(dataMotocaChega)) {
        setState(() {
          tempoEmMinutosAteOMotocaChegar = "0";
        });
      } else {
        setState(() {
          tempoEmMinutosAteOMotocaChegar =
              (dataMotocaChega.difference(dataAtual).inMinutes + 1).toString();
        });
      }
      Timer(const Duration(seconds: 30),
          () => buscarTempoQueMotocaChegaEmMinutos());
    }
  }

  validarBotaoCancelarCorrida() {
    // var dataInicioCorrida = DateTime.fromMicrosecondsSinceEpoch(
    //     corridaAtual["dataInicioCorrida"].millisecondsSinceEpoch * 1000);

    // if (dataInicioCorrida
    //     .add(Duration(
    //         minutes: int.parse(tempoMinimoEmMinutosParaCancelarCorrida)))
    //     .isAfter(DateTime.now())) {
    //   return true;
    // }

    if (tempoEmMinutosAteOMotocaChegar == "0") {
      return true;
    }

    return false;
  }
}
