import 'package:Motoca/Motoca/NavDrawerMotoca.dart';
import 'package:Motoca/Motoca/Singletons/motoca_singleton.dart';
import 'package:Motoca/Motoca/cadastroMotoca.dart';
import 'package:Motoca/Motoca/controller/moto_controller.dart';
import 'package:Motoca/Motoca/controller/motoca_controller.dart';
import 'package:Motoca/Motoca/inicioMotoca.dart';
import 'package:Motoca/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import '../util.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:uuid/uuid.dart';

FirebaseAuth auth = FirebaseAuth.instance;
TextEditingController controllerCodigo = TextEditingController();

class Motos extends StatelessWidget {
  const Motos({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InicioMotoca()),
            (Route<dynamic> route) => false);
        return Future.value(true);
      },
      child: Scaffold(
        drawer: const NavDrawerMotoca(),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Minhas motos"),
            ],
          ),
        ),
        body: const MotosPage(),
      ),
    );
  }
}

class MotosPage extends StatefulWidget {
  const MotosPage({Key? key}) : super(key: key);

  @override
  State<MotosPage> createState() => _MotosPageState();
}

class _MotosPageState extends State<MotosPage> {
  late User usuarioLogado;
  bool inserindoMoto = true;
  final _controller = ScrollController();
  final TextEditingController _controllerPlaca = TextEditingController();

  String dropdownValueMarca = "Marca";
  String dropdownValueCorMoto = "Cor";
  String dropdownValueAnoMoto = "Ano";
  List<String> marcaMotos = ["Marca"];
  List<String> corMotos = [
    "Cor",
  ];
  List<String> anoMotos = [
    "Ano",
  ];

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      buscarMarcas().then((value) {
        List<String> motosList = [];
        for (var item in value) {
          motosList.add(item["marca"]);
        }
        setState(() {
          marcaMotos.addAll(motosList);
        });
      });

      buscarCores().then((value) {
        List<String> coresList = [];
        for (var item in value) {
          coresList.add(item["cor"]);
        }
        setState(() {
          corMotos.addAll(coresList);
        });
      });

      buscarAnos().then((value) {
        List<String> anoList = [];
        for (var item in value) {
          anoList.add(item["ano"]);
        }
        setState(() {
          anoMotos.addAll(anoList);
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() {
            _controllerPlaca.text = "";
            dropdownValueMarca = "Marca";
            dropdownValueAnoMoto = "Ano";
            dropdownValueCorMoto = "Cor";
            inserindoMoto = true;
          });
          await novaMoto("", "");
        },
        label: const Text('Nova Moto'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.greenAccent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: FutureBuilder(
                future:
                    buscarPerfilMotoca(SingletonMotoca.instance.getUsuarioId()),
                builder: (context, AsyncSnapshot snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    return ListView.builder(
                        itemCount: snapshot.data["motos"].length,
                        scrollDirection: Axis.vertical,
                        controller: _controller,
                        itemBuilder: (BuildContext context, int index) {
                          var statusMoto = snapshot.data["motos"][index]
                                  ["status"]
                              .toString();

                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                snapshot.data["motos"][index]
                                                            ["placa"]
                                                        .toString()
                                                        .toUpperCase() +
                                                    " - ",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                statusMoto.toUpperCase(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: statusMoto == "ativa"
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              )
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                snapshot.data["motos"][index]
                                                            ["marca"]
                                                        .toString()
                                                        .toUpperCase() +
                                                    " " +
                                                    snapshot.data["motos"]
                                                            [index]["ano"]
                                                        .toString()
                                                        .toUpperCase() +
                                                    " - " +
                                                    snapshot.data["motos"]
                                                            [index]["cor"]
                                                        .toString()
                                                        .toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          statusMoto == "desativada"
                                              ? DialogButton(
                                                  color: Colors.green,
                                                  child: Row(
                                                    children: const [
                                                      Icon(
                                                        Icons.refresh,
                                                        color: Colors.white,
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () async {
                                                    ativarMoto(
                                                        snapshot.data["motos"]
                                                            [index]["placa"],
                                                        snapshot.data["motos"]
                                                            [index]["id"]);
                                                  })
                                              : const SizedBox(),
                                          statusMoto != "ativa"
                                              ? DialogButton(
                                                  color: Colors.red,
                                                  child: Row(
                                                    children: const [
                                                      Icon(
                                                        Icons.cancel,
                                                        color: Colors.white,
                                                      ),
                                                    ],
                                                  ),
                                                  onPressed: () async {
                                                    apagarMoto(
                                                        snapshot.data["motos"]
                                                            [index]["placa"],
                                                        snapshot.data["motos"]
                                                            [index]["id"]);
                                                  })
                                              : const SizedBox(),
                                          DialogButton(
                                              color: Colors.greenAccent,
                                              child: Row(
                                                children: const [
                                                  Icon(
                                                    Icons.edit,
                                                    color: Colors.black,
                                                  ),
                                                ],
                                              ),
                                              onPressed: () async {
                                                setState(() {
                                                  _controllerPlaca.text =
                                                      snapshot.data["motos"]
                                                          [index]["placa"];
                                                  dropdownValueAnoMoto =
                                                      snapshot.data["motos"]
                                                          [index]["ano"];
                                                  dropdownValueCorMoto =
                                                      snapshot.data["motos"]
                                                          [index]["cor"];
                                                  dropdownValueMarca =
                                                      snapshot.data["motos"]
                                                          [index]["marca"];
                                                  inserindoMoto = false;
                                                });
                                                novaMoto(
                                                    snapshot.data["motos"]
                                                        [index]["id"],
                                                    statusMoto);
                                              })
                                        ],
                                      ),
                                    ]),
                                const Divider(
                                  height: 0,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          );
                        });
                  }
                }),
          ),
        ],
      ),
    );
  }

  Future<void> novaMoto(String motoId, String statusMoto) async {
    await Alert(
        context: context,
        title: inserindoMoto ? "Cadastrar Moto" : "Alterar Moto",
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controllerPlaca,
                      maxLength: 7,
                      autofocus: true,
                      cursorColor: Colors.black,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(color: Colors.black),
                        hintText: 'Digite a placa da moto',
                        hintStyle: TextStyle(color: Colors.black),
                        fillColor: Colors.black,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          value: dropdownValueMarca,
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
                              dropdownValueMarca = newValue!;
                            });
                          },
                          items: marcaMotos
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        DropdownButton<String>(
                          value: dropdownValueAnoMoto,
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
                              dropdownValueAnoMoto = newValue!;
                            });
                          },
                          items: anoMotos
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          value: dropdownValueCorMoto,
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
                              dropdownValueCorMoto = newValue!;
                            });
                          },
                          items: corMotos
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        style: const AlertStyle(backgroundColor: Colors.white),
        buttons: [
          DialogButton(
            color: Colors.red,
            child: const Text(
              "Voltar",
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
              "Salvar",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              if (validarDados()) {
                if (inserindoMoto) {
                  var moto = {
                    'placa': _controllerPlaca.text,
                    'marca': dropdownValueMarca,
                    'ano': dropdownValueAnoMoto,
                    'cor': dropdownValueCorMoto,
                    'id': const Uuid().v1(),
                    'status': 'desativada'
                  };
                  try {
                    await inserirMoto(moto);
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() {
                      buscarPerfilMotoca(
                          SingletonMotoca.instance.getUsuarioId());
                      _controllerPlaca.text = "";
                      dropdownValueMarca = "Marca";
                      dropdownValueAnoMoto = "Ano";
                      dropdownValueCorMoto = "Cor";
                    });
                  } catch (e) {
                    exibirToastTop("Erro ao tentar inserir a moto");
                  }
                } else {
                  var moto = {
                    'placa': _controllerPlaca.text,
                    'marca': dropdownValueMarca,
                    'ano': dropdownValueAnoMoto,
                    'cor': dropdownValueCorMoto,
                    'id': motoId,
                    'status': statusMoto
                  };
                  try {
                    await atualizarMoto(moto);
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() {
                      buscarPerfilMotoca(
                          SingletonMotoca.instance.getUsuarioId());
                      _controllerPlaca.text = "";
                      dropdownValueMarca = "Marca";
                      dropdownValueAnoMoto = "Ano";
                      dropdownValueCorMoto = "Cor";
                    });
                  } catch (e) {
                    exibirToastTop("Erro ao tentar atualizar a moto");
                  }
                }
              }
            },
          )
        ]).show();
  }

  ativarMoto(String placa, String id) async {
    await Alert(
      context: context,
      title: "Deseja realmente ativar a moto " + placa.toUpperCase() + "?",
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
            Navigator.of(context).pop();
          },
        ),
        DialogButton(
          color: Colors.greenAccent,
          child: const Text(
            "Sim",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await ativarMotoMotoca(id);
            setState(() {
              buscarPerfilMotoca(SingletonMotoca.instance.getUsuarioId());
            });
          },
        ),
      ],
    ).show();
  }

  apagarMoto(String placa, String id) async {
    await Alert(
      context: context,
      title: "Deseja realmente apagar a moto " + placa.toUpperCase() + "?",
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
            Navigator.of(context).pop();
          },
        ),
        DialogButton(
          color: Colors.greenAccent,
          child: const Text(
            "Sim",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            await excluirMoto(id);
            setState(() {
              buscarPerfilMotoca(SingletonMotoca.instance.getUsuarioId());
            });
          },
        ),
      ],
    ).show();
  }

  bool validarDados() {
    if (_controllerPlaca.text.isEmpty || _controllerPlaca.text.length != 7) {
      exibirToastTop("Preencha a placa da moto");
      return false;
    }
    if (dropdownValueMarca == "Marca") {
      exibirToastTop("Preencha a marca da moto");
      return false;
    }
    if (dropdownValueAnoMoto == "Ano") {
      exibirToastTop("Preencha o ano da moto");
      return false;
    }
    if (dropdownValueCorMoto == "Cor") {
      exibirToastTop("Preencha a cor da moto");
      return false;
    }

    return true;
  }
}
