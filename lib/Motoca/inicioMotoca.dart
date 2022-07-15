import 'dart:async';

import 'package:Motoca/Cliente/controller/corrida_controller.dart';
import 'package:Motoca/Motoca/NavDrawerMotoca.dart';
import 'package:Motoca/Motoca/Singletons/motoca_singleton.dart';
import 'package:Motoca/Motoca/cadastroMotoca.dart';
import 'package:Motoca/Motoca/controller/motoca_controller.dart';
import 'package:Motoca/Motoca/controller/raio_controller.dart';
import 'package:Motoca/Motoca/corridaAtiva.dart';
import 'package:Motoca/main.dart';
import 'package:Motoca/util.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

FirebaseAuth auth = FirebaseAuth.instance;
TextEditingController controllerCodigo = TextEditingController();
String googleApiKey = "AIzaSyAhKKkgVrl2sqAG-rB8s-QbA4lS06hwAu4";
double porcentagemAdm = 0.0;

class InicioMotoca extends StatelessWidget {
  const InicioMotoca({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavDrawerMotoca(),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Motoca"),
          ],
        ),
      ),
      body: const InicioMotocaPage(),
    );
  }
}

class InicioMotocaPage extends StatefulWidget {
  const InicioMotocaPage({Key? key}) : super(key: key);

  @override
  State<InicioMotocaPage> createState() => _InicioMotocaPageState();
}

class _InicioMotocaPageState extends State<InicioMotocaPage> {
  late User usuarioLogado;
  late dynamic perfilMotoca;
  bool temPerfilMotoca = false;
  bool temPagamentoParaRealizar = false;
  List<dynamic> corridasAtuais = <dynamic>[];
  List<dynamic> corridasAtuaisFiltrada = <dynamic>[];
  final _controller = ScrollController();
  late Position localizacaoMotoca;
  bool temLocalizacaoMotoca = false;
  List<dynamic> raios = <dynamic>[];
  String cidadeMotoca = "";
  int QtdDiasParaLiberarAppPagamentoMotoca = 0;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      try {
        localizacaoMotoca = await pegarLocalizacao();
        setState(() {
          temLocalizacaoMotoca = true;
        });
        if (temLocalizacaoMotoca) {
          await pegarKeys();
          cidadeMotoca = (await latlongParaEndereco(localizacaoMotoca.latitude,
                  localizacaoMotoca.longitude, googleApiKey))
              .cidade;
        }
      } catch (e) {
        exibirToastTop(e.toString());
        setState(() {
          temLocalizacaoMotoca = false;
        });
      }
      await verificarCadastroMotoca();
      await buscarRaios();
      filtrarCorridasPorRaio();
    });
    super.initState();
  }

  pegarKeys() async {
    CollectionReference keys = FirebaseFirestore.instance.collection('Keys');
    var docs = await keys.get();
    if (docs.size > 0) {
      googleApiKey = docs.docs.first["googleApiKey"];
      porcentagemAdm = docs.docs.first["porcentagemAdm"];
      QtdDiasParaLiberarAppPagamentoMotoca =
          docs.docs.first["QtdDiasParaLiberarAppPagamentoMotoca"];
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              temPerfilMotoca
                  ? FloatingActionButton.extended(
                      onPressed: null,
                      backgroundColor: Colors.red,
                      label: Text(cidadeMotoca,
                          style: const TextStyle(color: Colors.white)),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
        body: temPagamentoParaRealizar
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: DialogButton(
                    color: Colors.red,
                    child: const Text(
                      "Realizar Pagamento do Repasse",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () async {
                      solicitarPagamento();
                    },
                  ),
                ),
              )
            : temLocalizacaoMotoca
                ? corridasAtuaisFiltrada.isNotEmpty
                    ? ListView.builder(
                        itemCount: corridasAtuaisFiltrada.length,
                        scrollDirection: Axis.vertical,
                        controller: _controller,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            margin: const EdgeInsets.all(20),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        corridasAtuaisFiltrada[index]["nome"],
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const Text(
                                        "Procurando Motorista",
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Forma Pagamento: " +
                                            corridasAtuaisFiltrada[index]
                                                ["formaPagamento"],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 15),
                                      ),
                                      Text(
                                        "Km: " +
                                            corridasAtuaisFiltrada[index]["km"]
                                                .toString(),
                                        style: const TextStyle(
                                            color: Colors.black,
                                            // fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      corridasAtuaisFiltrada[index]
                                                  ["formaPagamento"] ==
                                              "Dinheiro"
                                          ? Text(
                                              "Troco para: R\$" +
                                                  corridasAtuaisFiltrada[index]
                                                      ["troco"],
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15),
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                                  const Divider(
                                    height: 0,
                                    color: Colors.black,
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      Text(
                                        "Endereco Origem: " +
                                            corridasAtuaisFiltrada[index]
                                                ["endereco"]["enderecoOrigem"],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 15),
                                      ),
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      Text(
                                        "Endereco Destino: " +
                                            corridasAtuaisFiltrada[index]
                                                ["endereco"]["enderecoDestino"],
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 15),
                                      ),
                                      const SizedBox(
                                        height: 15,
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                    height: 0,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Repasse: R\$" +
                                            ((double.parse(
                                                        corridasAtuaisFiltrada[
                                                            index]["preco"]) *
                                                    porcentagemAdm))
                                                .toStringAsFixed(2),
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17),
                                      ),
                                      Text(
                                        "Corrida: R\$" +
                                            corridasAtuaisFiltrada[index]
                                                ["preco"],
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () async {
                                            Uri googleUrl = Uri.parse("https://www.google.com/maps/dir/" +
                                                corridasAtuaisFiltrada[index]["endereco"]
                                                            ["latLongEnderecoOrigem"]
                                                        [0]
                                                    .toString() +
                                                "," +
                                                corridasAtuaisFiltrada[index]
                                                                ["endereco"]
                                                            ["latLongEnderecoOrigem"]
                                                        [1]
                                                    .toString() +
                                                "/" +
                                                corridasAtuaisFiltrada[index]
                                                                ["endereco"]
                                                            ["latLongEnderecoDestino"]
                                                        [0]
                                                    .toString() +
                                                "," +
                                                corridasAtuaisFiltrada[index]
                                                            ["endereco"]
                                                        ["latLongEnderecoDestino"][1]
                                                    .toString());
                                            if (await launchUrl(googleUrl,
                                                mode: LaunchMode
                                                    .externalApplication)) {
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
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                side: const BorderSide(
                                                    color: Colors.greenAccent),
                                              ),
                                            ),
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(Colors.greenAccent),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(
                                                Icons.location_on,
                                                color: Colors.black,
                                              ),
                                              Text(
                                                "Ver Rota",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            pegarCorrida(
                                                corridasAtuaisFiltrada[index]
                                                    .id);
                                          },
                                          style: ButtonStyle(
                                            padding: MaterialStateProperty.all<
                                                    EdgeInsetsGeometry>(
                                                const EdgeInsets.all(5)),
                                            shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                side: const BorderSide(
                                                    color: Colors.greenAccent),
                                              ),
                                            ),
                                            backgroundColor:
                                                MaterialStateProperty.all<
                                                    Color>(Colors.greenAccent),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5),
                                            child: Text(
                                              "Pegar Corrida",
                                              style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                    : const Center(child: Text("Não tem corridas no momento"))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                          "Ative sua localização para procurar corridas"),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 5),
                        child: DialogButton(
                          color: Colors.red,
                          child: const Text(
                            "Buscar localização",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () async {
                            try {
                              localizacaoMotoca = await pegarLocalizacao();
                              setState(() {
                                temLocalizacaoMotoca = true;
                              });
                            } catch (e) {
                              exibirToastTop(e.toString());
                              setState(() {
                                temLocalizacaoMotoca = false;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ));
  }

  verificarCadastroMotoca() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        user.reload();
        usuarioLogado = user;
        var userId = usuarioLogado.uid;
        SingletonMotoca.instance.setUsuarioId(userId);
        await buscarCorridaAtivaMotoca(userId).then((value) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const CorridaAtiva()),
              (Route<dynamic> route) => false);
        }).catchError((e) {
          buscarPerfilMotoca(userId).then((value) async {
            setState(() {
              perfilMotoca = value;
              temPerfilMotoca = true;
            });
            if (perfilMotoca["bloqueado"] == "sim") {
              exibirToastTop("Usuário bloqueado");
              usuarioBloqueado();
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyApp()),
                  (Route<dynamic> route) => false);
            }
            if (perfilMotoca["contratosRecebendo"] != null) {
              if (DateTime.fromMicrosecondsSinceEpoch(
                      perfilMotoca["contratosRecebendo"]["data"]
                              .millisecondsSinceEpoch *
                          1000)
                  .add(Duration(days: QtdDiasParaLiberarAppPagamentoMotoca))
                  .isBefore(DateTime.now())) {
                setState(() {
                  temPagamentoParaRealizar = true;
                });
              }
              solicitarPagamento();
            }
            adicionarListenerProcurandoCorridas();
          }).catchError((error, stackTrace) {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const CadastroMotoca()),
                (Route<dynamic> route) => false);
          });
        });
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
            (Route<dynamic> route) => false);
      }
    });
  }

  buscarRaios() async {
    await buscarRaiosController().then((value) {
      raios = value;
      raios
          .sort((a, b) => a["tempoEmSegundos"].compareTo(b["tempoEmSegundos"]));
    });
  }

  bool validarSeACorridaPodeSerPegaPeloMotoca(dynamic corrida) {
    var dataCorrida = DateTime.fromMicrosecondsSinceEpoch(
        corrida["data"].millisecondsSinceEpoch * 1000);
    var qtdSegundosPassouDaCorrida =
        DateTime.now().difference(dataCorrida).inSeconds;

    double raioQueDevePegar = 0;
    for (var r in raios) {
      if (qtdSegundosPassouDaCorrida > int.parse(r["tempoEmSegundos"])) {
        raioQueDevePegar = double.parse(r["km"].toString());
      }
    }
    var latEnderecoOrigem = corrida["endereco"]["latLongEnderecoOrigem"][0];
    var longEnderecoOrigem = corrida["endereco"]["latLongEnderecoOrigem"][1];

    var distanciaEntreCorridaEEntregador = calcularDistanciaEntreCoordenadas(
        double.parse(latEnderecoOrigem.toString()),
        double.parse(longEnderecoOrigem.toString()),
        localizacaoMotoca.latitude,
        localizacaoMotoca.longitude);

    if (distanciaEntreCorridaEEntregador > raioQueDevePegar) {
      return false;
    } else {
      return true;
    }
  }

  Future adicionarListenerProcurandoCorridas() async {
    FirebaseFirestore.instance
        .collection('Corridas')
        .where("status", isEqualTo: "procurando")
        .where("endereco.cidade", isEqualTo: cidadeMotoca)
        .snapshots()
        .listen((event) async {
      for (var element in event.docChanges) {
        var corrida = await buscarCorridaPorId(element.doc.id);
        if (corrida["status"] != "procurando") {
          setState(() {
            corridasAtuais.removeWhere((element) => element.id == corrida.id);
          });
        } else if (corridasAtuais.any((element) => element.id == corrida.id)) {
          setState(() {
            corridasAtuais.removeWhere((element) => element.id == corrida.id);
            corridasAtuais.add(corrida);
          });
        } else {
          setState(() {
            corridasAtuais.add(corrida);
          });
        }
      }
    });
  }

  filtrarCorridasPorRaio() async {
    localizacaoMotoca = await pegarLocalizacao();
    setState(() {
      corridasAtuaisFiltrada = [];
    });
    for (var corrida in corridasAtuais) {
      if (validarSeACorridaPodeSerPegaPeloMotoca(corrida)) {
        setState(() {
          corridasAtuaisFiltrada.add(corrida);
        });
      }
    }

    Timer(const Duration(seconds: 10), () => filtrarCorridasPorRaio());
  }

  pegarCorrida(String corridaId) async {
    showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2021),
            lastDate: DateTime(2222),
            initialEntryMode: DatePickerEntryMode.calendarOnly,
            helpText: "Selecione a data que vai chegar no local")
        .then((value) async {
      if (value != null) {
        final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
            helpText: "Selecione a hora que vai chegar no local");
        if (picked != null) {
          var tempoDestino = DateTime(
              value.year, value.month, value.day, picked.hour, picked.minute);
          if (tempoDestino.isBefore(DateTime.now())) {
            exibirToastTop("A data de chegada é menor que a data atual");
          } else {
            // await alterarStatusMotoca(perfilMotoca.id, "nao");
            await atribuirMotoca(
                corridaId, perfilMotoca.data(), tempoDestino, porcentagemAdm);
            buscarCorridaAtivaMotoca(SingletonMotoca.instance.getUsuarioId())
                .then((value) {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const CorridaAtiva()),
                  (Route<dynamic> route) => false);
            });
          }
        }
      }
    });
  }

  solicitarPagamento() async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => Dialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Container(
                alignment: FractionalOffset.center,
                height: 300,
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Para continuar utilizando nossos serviços realize o pagamento do repasse",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      "Referente ao mês: " +
                          perfilMotoca["contratosRecebendo"]["mes"]
                              .toString()
                              .split("-")[1] +
                          "/" +
                          perfilMotoca["contratosRecebendo"]["mes"]
                              .toString()
                              .split("-")[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 17),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      "Total a pagar: R\$" +
                          perfilMotoca["contratosRecebendo"]["totalRepasse"]
                              .toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 17),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: InkWell(
                          child: const Text(
                            'Copiar PIX',
                            style: TextStyle(color: Colors.blue, fontSize: 22),
                          ),
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: perfilMotoca["contratosRecebendo"]
                                    ["linkPagamento"]));
                            exibirToastTop("Código do PIX copiado com sucesso");
                          }),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      "O pagamento tem até 1 dia útil para ser validado",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                  ],
                ),
              ),
            ));
  }

  usuarioBloqueado() async {
    showDialog(
        context: context,
        builder: (_) => Dialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Container(
                alignment: FractionalOffset.center,
                height: 120,
                padding: const EdgeInsets.only(left: 15, right: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "Usuário bloqueado, caso queira entrar em contato nos envie um email para: motocaapp@gmail.com",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                  ],
                ),
              ),
            ));
  }
}
