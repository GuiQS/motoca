import 'package:Motoca/Cliente/NavDrawer.dart';
import 'package:Motoca/Cliente/Singletons/Singletons_nav.dart';
import 'package:Motoca/Cliente/inicioCliente.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Motoca/Cliente/controller/corrida_controller.dart';
import 'package:intl/intl.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class Extrato extends StatefulWidget {
  const Extrato({Key? key}) : super(key: key);

  @override
  State<Extrato> createState() => _ExtratoState();
}

class _ExtratoState extends State<Extrato> {
  dynamic corridas = [];
  double somaPrecos = 0;
  int qtdCorridas = 0;
  double kmsRodados = 0;
  DateTime dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime dataFim = DateTime.now();

  @override
  void initState() {
    SingletonNav.instance.setContext(context);
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
        drawer: const NavDrawer(),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Extrato"),
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
        body: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
                        size: 50,
                      ),
                      Text(
                        "Valor Gasto: R\$" + somaPrecos.toString(),
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
                        size: 50,
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
                        size: 50,
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
    return buscarCorridasFinalizadasUsuario(
            FirebaseAuth.instance.currentUser?.uid ?? "", dataInicio, dataFim)
        .then((value) {
      corridas = value;
      somaPrecos = 0;
      kmsRodados = 0;
      for (var i = 0; i < corridas.length; i++) {
        somaPrecos += double.parse(corridas[i]["preco"]);
        kmsRodados += corridas[i]["km"];
      }
      setState(() {
        somaPrecos = somaPrecos;
        qtdCorridas = corridas.length;
        kmsRodados = double.parse(kmsRodados.toStringAsFixed(2));
      });
      return corridas;
    });
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
        ],
      ),
      buttons: [],
    ).show().then((value) {
      buscarCorridas();
    });
  }
}
