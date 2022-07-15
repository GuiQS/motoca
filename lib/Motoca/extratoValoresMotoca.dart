import 'package:Motoca/Cliente/inicioCliente.dart';
import 'package:Motoca/Motoca/NavDrawerMotoca.dart';
import 'package:Motoca/Motoca/Singletons/motoca_singleton.dart';
import 'package:Motoca/Motoca/controller/motoca_controller.dart';
import 'package:flutter/material.dart';
import 'package:Motoca/Cliente/controller/corrida_controller.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class ExtratoValoresMotoca extends StatefulWidget {
  const ExtratoValoresMotoca({Key? key}) : super(key: key);

  @override
  State<ExtratoValoresMotoca> createState() => _ExtratoValoresMotocaState();
}

class _ExtratoValoresMotocaState extends State<ExtratoValoresMotoca> {
  dynamic corridas = [];
  double valorTotalGanho = 0;
  double valorRepasse = 0;
  int qtdCorridas = 0;
  double kmsRodados = 0;
  DateTime dataInicio =
      DateTime.now().subtract(Duration(days: DateTime.now().day - 1));
  DateTime dataFim = DateTime.now();

  late dynamic perfilMotoca;
  bool temPerfilMotoca = false;

  @override
  void initState() {
    buscarMotoca();
    buscarCorridas();
    super.initState();
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
        drawer: const NavDrawerMotoca(),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Extrato de Valores"),
            ],
          ),
        ),
        floatingActionButton: temPerfilMotoca
            ? FloatingActionButton.extended(
                onPressed: () {},
                // child: const Icon(Icons.rel),
                label: Text(
                  motocaPagouDataFiltrada()
                      ? "Pagamento realizado"
                      : "Pagamento não realizado",
                  style: TextStyle(
                      color: motocaPagouDataFiltrada()
                          ? Colors.black
                          : Colors.white),
                ),
                icon: Icon(
                  Icons.note_outlined,
                  color:
                      motocaPagouDataFiltrada() ? Colors.black : Colors.white,
                ),
                backgroundColor:
                    motocaPagouDataFiltrada() ? Colors.greenAccent : Colors.red,
              )
            : const SizedBox(),
        body: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        showMonthPicker(
                          context: context,
                          firstDate: DateTime(DateTime.now().year - 1, 5),
                          lastDate: DateTime(DateTime.now().year + 1, 9),
                          initialDate: dataInicio,
                        ).then((date) {
                          if (date != null) {
                            setState(() {
                              dataInicio = date;
                              dataFim = DateTime(date.year, date.month + 1, 0);
                            });
                            buscarCorridas();
                          }
                        });
                      },
                      label: Text('Selecione a Data: ' +
                          DateFormat('MM/yyyy').format(dataInicio)),
                      icon: const Icon(Icons.date_range),
                      backgroundColor: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.black,
                        size: 30,
                      ),
                      Text(
                        "Valor Ganho: R\$" + valorTotalGanho.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        color: Colors.black,
                        size: 30,
                      ),
                      Text(
                        "Valor Repasse: R\$" + valorRepasse.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.motorcycle,
                        color: Colors.black,
                        size: 30,
                      ),
                      Text(
                        "Quantidade de Corridas: " + qtdCorridas.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.only(bottom: 30),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.speed,
                        color: Colors.black,
                        size: 30,
                      ),
                      Text(
                        "Kms Rodados: " + kmsRodados.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  buscarCorridas() async {
    return buscarCorridasFinalizadasMotoca(
            SingletonMotoca.instance.getUsuarioId(), dataInicio, dataFim)
        .then((value) {
      corridas = value;
      valorTotalGanho = 0;
      valorRepasse = 0;
      kmsRodados = 0;
      for (var i = 0; i < corridas.length; i++) {
        valorTotalGanho += double.parse(corridas[i]["preco"]);
        valorRepasse += double.parse(corridas[i]["repasse"]);
        kmsRodados += corridas[i]["km"];
      }
      setState(() {
        valorTotalGanho = valorTotalGanho;
        valorRepasse = valorRepasse;
        qtdCorridas = corridas.length;
        kmsRodados = double.parse(kmsRodados.toStringAsFixed(2));
      });
      return corridas;
    });
  }

  buscarMotoca() {
    buscarPerfilMotoca(SingletonMotoca.instance.getUsuarioId())
        .then((value) async {
      setState(() {
        perfilMotoca = value;
        temPerfilMotoca = true;
      });
    });
  }

  motocaPagouDataFiltrada() {
    return perfilMotoca["contratosPagos"].any((element) =>
        element["mes"] == DateFormat('yyyy-MM').format(dataInicio));
  }

  // filtrosPreDefinidos() async {
  //   await Alert(
  //     context: context,
  //     title: "Selecione o filtro",
  //     style: const AlertStyle(backgroundColor: Colors.white),
  //     content: Column(
  //       children: [
  //         const SizedBox(
  //           height: 20,
  //         ),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: DialogButton(
  //                 color: Colors.greenAccent,
  //                 child: const Text(
  //                   "Semanal",
  //                   style: TextStyle(
  //                     color: Colors.black,
  //                   ),
  //                 ),
  //                 onPressed: () {
  //                   dataInicio = DateTime.now();
  //                   setState(() {
  //                     dataInicio = dataInicio
  //                         .subtract(Duration(days: dataInicio.weekday));

  //                     dataFim = DateTime.now();
  //                   });
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: DialogButton(
  //                 color: Colors.greenAccent,
  //                 child: const Text(
  //                   "Mensal",
  //                   style: TextStyle(
  //                     color: Colors.black,
  //                   ),
  //                 ),
  //                 onPressed: () {
  //                   dataInicio = DateTime.now();
  //                   setState(() {
  //                     dataInicio = dataInicio
  //                         .subtract(Duration(days: dataInicio.day - 1));
  //                     dataFim = DateTime.now();
  //                   });
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: DialogButton(
  //                 color: Colors.greenAccent,
  //                 child: const Text(
  //                   "Anual",
  //                   style: TextStyle(
  //                     color: Colors.black,
  //                   ),
  //                 ),
  //                 onPressed: () {
  //                   setState(() {
  //                     dataInicio = DateTime(DateTime.now().year, 1, 1);
  //                     dataFim = DateTime.now();
  //                   });
  //                   Navigator.of(context).pop();
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //     buttons: [],
  //   ).show().then((value) {
  //     buscarCorridas();
  //   });
  // }
}
