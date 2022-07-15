import 'package:Motoca/Cliente/controller/corrida_controller.dart';
import 'package:Motoca/Motoca/NavDrawerMotoca.dart';
import 'package:Motoca/Motoca/Singletons/motoca_singleton.dart';
import 'package:Motoca/Motoca/cadastroMotoca.dart';
import 'package:Motoca/Motoca/controller/moto_controller.dart';
import 'package:Motoca/Motoca/controller/motoca_controller.dart';
import 'package:Motoca/Motoca/inicioMotoca.dart';
import 'package:Motoca/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import '../util.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class CorridaAtiva extends StatelessWidget {
  const CorridaAtiva({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Corrida Atual"),
          ],
        ),
      ),
      body: const CorridaAtivaPage(),
    );
  }
}

class CorridaAtivaPage extends StatefulWidget {
  const CorridaAtivaPage({Key? key}) : super(key: key);

  @override
  State<CorridaAtivaPage> createState() => _CorridaAtivaPageState();
}

class _CorridaAtivaPageState extends State<CorridaAtivaPage> {
  late User usuarioLogado;
  bool buscandoCorridaAtiva = true;
  late dynamic corridaAtual;
  final TextEditingController controllerMotivoCancelamento =
      TextEditingController();
  bool usuarioQuerDigitarMotivoCancelamento = false;
  bool canceladoPeloMotoca = false;
  late dynamic perfilMotoca;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await verificarCadastroMotoca();
      await buscarCorridaAtiva();
      await adicionarListenerCorridaAtual();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          !buscandoCorridaAtiva && corridaAtual["status"] == "aceito"
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await iniciarCorrida(corridaAtual.id);
                    await buscarCorridaAtiva();
                    exibirToastTop("Corrida iniciada com sucesso");
                  },
                  backgroundColor: Colors.greenAccent,
                  label: const Text("Iniciar Corrida",
                      style: TextStyle(color: Colors.black)),
                )
              : !buscandoCorridaAtiva
                  ? FloatingActionButton.extended(
                      onPressed: () async {
                        await finalizarCorrida(corridaAtual.id);
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => const InicioMotoca()),
                            (Route<dynamic> route) => false);
                      },
                      backgroundColor: Colors.greenAccent,
                      label: const Text("Finalizar Corrida",
                          style: TextStyle(color: Colors.black)),
                    )
                  : const SizedBox(),
      body: buscandoCorridaAtiva
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(
                    width: 10,
                  ),
                  Text("Buscando corrida ativa"),
                ],
              ),
            )
          : Container(
              margin: const EdgeInsets.all(20),
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          corridaAtual["nome"],
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        corridaAtual["status"] == "aceito"
                            ? const Text(
                                "Corrida Aceita",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Text(
                                "Corrida em Andamento",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Forma Pagamento: " + corridaAtual["formaPagamento"],
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                        ),
                        Text(
                          "Km: " + corridaAtual["km"].toString(),
                          style: const TextStyle(
                              color: Colors.black,
                              // fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        corridaAtual["status"] == "aceito"
                            ? TextButton(
                                onPressed: () async {
                                  Uri googleUrl = Uri.parse(
                                      "https://www.google.com/maps/search/?api=1&query=" +
                                          corridaAtual["endereco"]
                                                  ["latLongEnderecoOrigem"][0]
                                              .toString() +
                                          "," +
                                          corridaAtual["endereco"]
                                                  ["latLongEnderecoOrigem"][1]
                                              .toString());
                                  if (await launchUrl(googleUrl,
                                      mode: LaunchMode.externalApplication)) {
                                  } else {
                                    exibirToastTop(
                                        "Não foi possível abrir o mapa");
                                  }
                                },
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all<
                                          EdgeInsetsGeometry>(
                                      const EdgeInsets.all(5)),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(
                                          color: Colors.greenAccent),
                                    ),
                                  ),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.greenAccent),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.black,
                                    ),
                                    Text(
                                      "Ir até o usuário",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 15),
                                    )
                                  ],
                                ),
                              )
                            : TextButton(
                                onPressed: () async {
                                  Uri googleUrl = Uri.parse(
                                      "https://www.google.com/maps/search/?api=1&query=" +
                                          corridaAtual["endereco"]
                                                  ["latLongEnderecoDestino"][0]
                                              .toString() +
                                          "," +
                                          corridaAtual["endereco"]
                                                  ["latLongEnderecoDestino"][1]
                                              .toString());
                                  if (await launchUrl(googleUrl,
                                      mode: LaunchMode.externalApplication)) {
                                  } else {
                                    exibirToastTop(
                                        "Não foi possível abrir o mapa");
                                  }
                                },
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all<
                                          EdgeInsetsGeometry>(
                                      const EdgeInsets.all(5)),
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: const BorderSide(
                                          color: Colors.greenAccent),
                                    ),
                                  ),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.greenAccent),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on,
                                      color: Colors.black,
                                    ),
                                    Text(
                                      "Ir até o destino",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 15),
                                    )
                                  ],
                                ),
                              ),
                        TextButton(
                          style: ButtonStyle(
                            padding:
                                MaterialStateProperty.all<EdgeInsetsGeometry>(
                                    const EdgeInsets.all(5)),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side:
                                    const BorderSide(color: Colors.greenAccent),
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.greenAccent),
                          ),
                          onPressed: () async {
                            Uri googleUrl = Uri.parse(
                                "tel://" + corridaAtual["telefone"].toString());
                            if (await launchUrl(googleUrl,
                                mode: LaunchMode.externalApplication)) {
                            } else {
                              exibirToastTop("Não foi possível abrir o mapa");
                            }
                          },
                          child: Row(
                            children: const [
                              Icon(
                                Icons.phone,
                                color: Colors.black,
                              ),
                              Text(
                                "Realizar Ligação",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(
                      height: 0,
                      color: Colors.black,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          "Endereco Origem: " +
                              corridaAtual["endereco"]["enderecoOrigem"],
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          "Endereco Destino: " +
                              corridaAtual["endereco"]["enderecoDestino"],
                          style: const TextStyle(
                              color: Colors.black, fontSize: 15),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Divider(
                      height: 0,
                      color: Colors.black,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: ButtonStyle(
                            padding:
                                MaterialStateProperty.all<EdgeInsetsGeometry>(
                                    const EdgeInsets.all(5)),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          onPressed: () {
                            exibirAlertaCancelarCorrida(context);
                          },
                          child: Row(
                            children: const [
                              Icon(
                                Icons.cancel,
                                color: Colors.white,
                              ),
                              Text(
                                "Cancelar Corrida",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "R\$" + corridaAtual["preco"],
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 23),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  buscarCorridaAtiva() async {
    buscarCorridaAtivaMotoca(SingletonMotoca.instance.getUsuarioId())
        .then((value) {
      corridaAtual = value;
      setState(() {
        buscandoCorridaAtiva = false;
      });
    });
  }

  Future adicionarListenerCorridaAtual() async {
    String userId = SingletonMotoca.instance.getUsuarioId();
    FirebaseFirestore.instance
        .collection('Corridas')
        .where('motoca.userId', isEqualTo: userId)
        .where("status", whereIn: ["aceito", "andamento"])
        .snapshots()
        .listen((event) async {
          for (var element in event.docChanges) {
            var corrida = await buscarCorridaPorId(element.doc.id);
            var statusCorridaAtual = corrida.get("status");
            var motivoCancelamento = "";
            try {
              motivoCancelamento = corrida.get("motivoCancelamento");
            } catch (e) {}

            if (statusCorridaAtual == "cancelado" && !canceladoPeloMotoca) {
              await corridaCancelada(motivoCancelamento);
            }
          }
        });
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
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const InicioMotoca()),
                (Route<dynamic> route) => false);
          },
        )
      ],
    ).show();
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
                          setState(() {
                            canceladoPeloMotoca = true;
                          });
                          await cancelarCorridaMotoca(
                              controllerMotivoCancelamento.text,
                              perfilMotoca.id);
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const InicioMotoca()),
                              (Route<dynamic> route) => false);
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
                          setState(() {
                            canceladoPeloMotoca = true;
                          });
                          await cancelarCorridaMotoca(
                              controllerMotivoCancelamento.text,
                              perfilMotoca.id);
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const InicioMotoca()),
                              (Route<dynamic> route) => false);
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
                    setState(() {
                      canceladoPeloMotoca = true;
                    });
                    await cancelarCorridaMotoca(
                        controllerMotivoCancelamento.text, perfilMotoca.id);
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (context) => const InicioMotoca()),
                        (Route<dynamic> route) => false);
                  } catch (e) {
                    exibirToastTop(e.toString());
                  }
                },
              )
            ]
          : [],
    ).show();
  }

  verificarCadastroMotoca() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        user.reload();
        usuarioLogado = user;
        var userId = usuarioLogado.uid;
        buscarPerfilMotoca(userId).then((value) {
          setState(() {
            perfilMotoca = value;
          });
        });
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
            (Route<dynamic> route) => false);
      }
    });
  }
}
