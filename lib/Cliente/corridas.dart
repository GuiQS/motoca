import 'package:Motoca/Cliente/NavDrawer.dart';
import 'package:Motoca/Cliente/Singletons/Singletons_nav.dart';
import 'package:Motoca/Cliente/inicioCliente.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Motoca/Cliente/controller/corrida_controller.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class Corridas extends StatefulWidget {
  const Corridas({Key? key}) : super(key: key);

  @override
  State<Corridas> createState() => _CorridasState();
}

class _CorridasState extends State<Corridas> {
  dynamic corridas = [];

  bool filtrarPorStatus = false;
  String statusParaFiltrar = "";

  bool filtrarQuemCancelou = false;
  bool canceladoPeloAdm = false;

  DateTime dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime dataFim = DateTime.now();

  int limit = 3;
  int totalItensTabela = 0;
  final _controller = ScrollController();

  @override
  void initState() {
    SingletonNav.instance.setContext(context);
    super.initState();
    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;
        if (!isTop && limit <= totalItensTabela) {
          setState(() {
            limit += 5;
            buscarCorridas();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InicioClient()),
            (Route<dynamic> route) => false);
        return Future.value(true);
      },
      child: Scaffold(
        drawer: const NavDrawer(),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Corridas"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            filtrosPreDefinidos();
          },
          child: const Icon(Icons.filter_alt),
          backgroundColor: Colors.greenAccent,
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            //       return buscarCorridasUsuario(FirebaseAuth.instance.currentUser?.uid ?? "",
            // statusFiltros, filtrarQuemCancelou, canceladoPeloAdm, limit);
            Text(
              filtrarQuemCancelou && canceladoPeloAdm
                  ? "Canceladas pelo motoca"
                  : filtrarQuemCancelou && !canceladoPeloAdm
                      ? "Canceladas pelo usuário"
                      : filtrarPorStatus
                          ? "Apenas " +
                              (statusParaFiltrar.toUpperCase() == "CANCELADO"
                                  ? "Canceladas"
                                  : "Finalizadas")
                          : "Todas ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: dataInicio,
                      firstDate: DateTime(2021),
                      lastDate: DateTime(2222),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          dataInicio = value;
                        });
                        buscarCorridas();
                      }
                    });
                  },
                  label: Text('Data Inicio: \n' +
                      DateFormat('dd/MM/yyyy').format(dataInicio)),
                  icon: const Icon(Icons.date_range),
                  backgroundColor: Colors.greenAccent,
                ),
                const SizedBox(
                  width: 20,
                ),
                FloatingActionButton.extended(
                  onPressed: () {
                    showDatePicker(
                      context: context,
                      initialDate: dataFim,
                      firstDate: DateTime(2021),
                      lastDate: DateTime(2222),
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          dataFim = value;
                        });
                        buscarCorridas();
                      }
                    });
                  },
                  label: Text('Data Fim: \n' +
                      DateFormat('dd/MM/yyyy').format(dataFim)),
                  icon: const Icon(Icons.date_range),
                  backgroundColor: Colors.greenAccent,
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder(
                  future: buscarCorridas(),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      if (snapshot.data.docs.toList().length == 0)
                        return Center(
                            child: Text("Nenhuma corrida encontrada"));

                      return ListView.builder(
                          itemCount: snapshot.data.docs.toList().length,
                          scrollDirection: Axis.vertical,
                          controller: _controller,
                          itemBuilder: (BuildContext context, int index) {
                            totalItensTabela =
                                snapshot.data.docs.toList().length;
                            var data = DateFormat('dd/MM/yyyy – kk:mm').format(
                                DateTime.parse(snapshot.data.docs[index]["data"]
                                    .toDate()
                                    .toString()));
                            var status = snapshot.data.docs[index]["status"]
                                .toUpperCase();
                            var formaPagamento =
                                snapshot.data.docs[index]["formaPagamento"];
                            var preco = snapshot.data.docs[index]["preco"];
                            var enderecoOrigem = snapshot.data.docs[index]
                                ["endereco"]["enderecoOrigem"];
                            var enderecoDestino = snapshot.data.docs[index]
                                ["endereco"]["enderecoDestino"];
                            var motivoCancelamento = "";
                            var motoca = "";
                            bool cancelamentoAdministrativo = true;
                            if (status == "CANCELADO") {
                              motivoCancelamento = snapshot.data.docs[index]
                                  ["motivoCancelamento"];
                              cancelamentoAdministrativo = snapshot.data
                                  .docs[index]["cancelamentoAdministrativo"];
                            }
                            if (status == "FINALIZADO") {
                              var moto = snapshot
                                      .data.docs[index]["motoca"]["motos"]
                                      .where((m) => m["status"] == "ativa")
                                      .first["marca"] +
                                  " " +
                                  snapshot.data.docs[index]["motoca"]["motos"]
                                      .where((m) => m["status"] == "ativa")
                                      .first["ano"] +
                                  " - " +
                                  snapshot.data.docs[index]["motoca"]["motos"]
                                      .where((m) => m["status"] == "ativa")
                                      .first["cor"];

                              motoca = snapshot.data.docs[index]["motoca"]
                                      ["nomeCompleto"] +
                                  ", " +
                                  moto +
                                  " - " +
                                  snapshot.data.docs[index]["motoca"]["motos"]
                                      .where((m) => m["status"] == "ativa")
                                      .first["placa"];
                            }
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white,
                                          ),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20))),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(data),
                                                Text(
                                                  status,
                                                  style: TextStyle(
                                                    color: status == "CANCELADO"
                                                        ? Colors.red
                                                        : status == "PROCURANDO"
                                                            ? Colors.yellow
                                                            : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(),
                                            status == "CANCELADO"
                                                ? Row(
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.red[400],
                                                            border: Border.all(
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  10),
                                                            ),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              "Motivo cancelamento: " +
                                                                  motivoCancelamento,
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                : const SizedBox(),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            status == "CANCELADO"
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(5),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.red[400],
                                                            border: Border.all(
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                            borderRadius:
                                                                const BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  10),
                                                            ),
                                                          ),
                                                          child: Center(
                                                              child: Text(
                                                            cancelamentoAdministrativo
                                                                ? "Cancelado pelo motoca"
                                                                : "Cancelado pelo usuário",
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          )),
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                : const SizedBox(),
                                            status == "CANCELADO"
                                                ? const Divider()
                                                : const SizedBox(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.greenAccent,
                                                      border: Border.all(
                                                        color: Colors.black,
                                                      ),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(10),
                                                      ),
                                                    ),
                                                    child: Center(
                                                        child: Text(
                                                      "Pagamento: " +
                                                          formaPagamento,
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    )),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.greenAccent,
                                                      border: Border.all(
                                                        color: Colors.black,
                                                      ),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(10),
                                                      ),
                                                    ),
                                                    child: Center(
                                                        child: Text(
                                                      "Preço: " +
                                                          preco.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    )),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    "Endereço origem: " +
                                                        enderecoOrigem,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    "Endereço destino: " +
                                                        enderecoDestino,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(),
                                            status == "FINALIZADO"
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          "Motoca: " + motoca,
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : const SizedBox(),
                                          ],
                                        ),
                                      ),
                                    ),
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
      ),
    );
  }

  Future<dynamic> buscarCorridas() async {
    var statusFiltros = ["finalizado", "cancelado", "aceito", "procurando"];
    if (filtrarPorStatus) statusFiltros = [statusParaFiltrar];

    return buscarCorridasUsuario(
        FirebaseAuth.instance.currentUser?.uid ?? "",
        statusFiltros,
        filtrarQuemCancelou,
        canceladoPeloAdm,
        limit,
        dataInicio,
        dataFim);
  }

  filtrosPreDefinidos() async {
    await Alert(
      context: context,
      title: "Selecione o filtro",
      style: const AlertStyle(backgroundColor: Colors.white),
      content: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.greenAccent,
                  child: const Text(
                    "Semanal",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    dataInicio = DateTime.now();
                    setState(() {
                      dataInicio = dataInicio
                          .subtract(Duration(days: dataInicio.weekday));

                      dataFim = DateTime.now();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.greenAccent,
                  child: const Text(
                    "Mensal",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    dataInicio = DateTime.now();
                    setState(() {
                      dataInicio = dataInicio
                          .subtract(Duration(days: dataInicio.day - 1));
                      dataFim = DateTime.now();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.greenAccent,
                  child: const Text(
                    "Anual",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      dataInicio = DateTime(DateTime.now().year, 1, 1);
                      dataFim = DateTime.now();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          const Divider(
            color: Colors.black,
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.greenAccent,
                  child: const Text(
                    "Todas",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    statusParaFiltrar = "";
                    filtrarPorStatus = false;
                    filtrarQuemCancelou = false;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.greenAccent,
                  child: const Text(
                    "Apenas Finalizadas",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () {
                    statusParaFiltrar = "finalizado";
                    filtrarPorStatus = true;
                    filtrarQuemCancelou = false;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.redAccent,
                  child: const Text(
                    "Apenas Canceladas",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    statusParaFiltrar = "cancelado";
                    filtrarPorStatus = true;
                    filtrarQuemCancelou = false;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.redAccent,
                  child: const Text(
                    "Canceladas pelo usuário",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    canceladoPeloAdm = false;
                    filtrarQuemCancelou = true;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: DialogButton(
                  color: Colors.redAccent,
                  child: const Text(
                    "Canceladas pelo motoca",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    filtrarQuemCancelou = true;
                    canceladoPeloAdm = true;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      buttons: [],
    ).show().then((value) {
      setState(() {
        buscarCorridas();
      });
    });
  }
}
