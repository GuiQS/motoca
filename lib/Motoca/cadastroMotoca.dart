import 'package:Motoca/Motoca/controller/cidade_controller.dart';
import 'package:Motoca/Motoca/controller/moto_controller.dart';
import 'package:Motoca/Motoca/controller/motoca_controller.dart';
import 'package:Motoca/Motoca/inicioMotoca.dart';
import 'package:Motoca/main.dart';
import 'package:Motoca/util.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';

FirebaseAuth auth = FirebaseAuth.instance;
TextEditingController controllerCodigo = TextEditingController();

class CadastroMotoca extends StatelessWidget {
  const CadastroMotoca({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text("Motoca"),
          ],
        ),
      ),
      body: const CadastroMotocaPage(),
    );
  }
}

class CadastroMotocaPage extends StatefulWidget {
  const CadastroMotocaPage({Key? key}) : super(key: key);

  @override
  State<CadastroMotocaPage> createState() => _CadastroMotocaPageState();
}

class _CadastroMotocaPageState extends State<CadastroMotocaPage> {
  late User usuarioLogado;
  final TextEditingController _controllerTelefone = TextEditingController();
  final TextEditingController _controllerCNH = TextEditingController();
  final TextEditingController _controllerPlaca = TextEditingController();
  String dropdownValueMarca = "Marca";
  String dropdownValueCorMoto = "Cor";
  String dropdownValueAnoMoto = "Ano";

  String dropdownValueCidades = "Selecione a Cidade";

  List<String> cidadesAtivas = ["Selecione a Cidade"];
  List<String> marcaMotos = ["Marca"];
  List<String> corMotos = [
    "Cor",
  ];
  List<String> anoMotos = [
    "Ano",
  ];

  var maskTelefone = MaskTextInputFormatter(
    mask: '+55 (##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  var maskPlaca = MaskTextInputFormatter(
    mask: '######',
    filter: {"#": RegExp(r'[0-9]')},
  );
  DateTime dataNascimento = DateTime.now();

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await buscarUsuarioLogado();
      buscarCidadesAtivas().then((value) {
        List<String> cidades = [];
        for (var item in value) {
          cidades.add(item["cidade"]);
        }
        setState(() {
          cidadesAtivas.addAll(cidades);
        });
      });

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Preencha as informações abaixo",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const Divider(),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      showDatePicker(
                        context: context,
                        initialDate: dataNascimento,
                        firstDate: DateTime(1950),
                        lastDate: DateTime(2222),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      ).then((value) {
                        if (value != null) {
                          setState(() {
                            dataNascimento = value;
                          });
                        }
                      });
                    },
                    label: Text('Nascimento \n' +
                        DateFormat('dd/MM/yyyy').format(dataNascimento)),
                    icon: const Icon(Icons.date_range),
                    backgroundColor: Colors.greenAccent,
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                DropdownButton<String>(
                  value: dropdownValueCidades,
                  icon: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                  ),
                  elevation: 16,
                  style: const TextStyle(color: Colors.black),
                  underline: Container(
                    height: 2,
                    color: Colors.white,
                  ),
                  dropdownColor: Colors.black,
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValueCidades = newValue!;
                    });
                  },
                  items: cidadesAtivas
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: _controllerTelefone,
              keyboardType: TextInputType.number,
              inputFormatters: [maskTelefone],
              onTap: () {
                // verificarComoUsuarioQuerEscolherLocalizacao("origem");
              },
              decoration: const InputDecoration(
                hintText: 'Digite seu telefone',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: _controllerCNH,
              keyboardType: TextInputType.number,
              maxLength: 15,
              onTap: () {
                // verificarComoUsuarioQuerEscolherLocalizacao("origem");
              },
              decoration: const InputDecoration(
                hintText: 'Digite sua CNH',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            TextField(
              controller: _controllerPlaca,
              // inputFormatters: [maskPlaca],
              maxLength: 7,
              onTap: () {
                // verificarComoUsuarioQuerEscolherLocalizacao("origem");
              },
              decoration: const InputDecoration(
                hintText: 'Digite a placa da moto',
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: const [
                Text("Selecione as informações de sua moto"),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DropdownButton<String>(
                  value: dropdownValueMarca,
                  icon: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                  ),
                  elevation: 16,
                  style: const TextStyle(color: Colors.black),
                  underline: Container(
                    height: 2,
                    color: Colors.white,
                  ),
                  dropdownColor: Colors.black,
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValueMarca = newValue!;
                    });
                  },
                  items:
                      marcaMotos.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: dropdownValueAnoMoto,
                  icon: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                  ),
                  elevation: 16,
                  style: const TextStyle(color: Colors.black),
                  underline: Container(
                    height: 2,
                    color: Colors.white,
                  ),
                  dropdownColor: Colors.black,
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValueAnoMoto = newValue!;
                    });
                  },
                  items: anoMotos.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: dropdownValueCorMoto,
                  icon: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                  ),
                  elevation: 16,
                  style: const TextStyle(color: Colors.black),
                  underline: Container(
                    height: 2,
                    color: Colors.white,
                  ),
                  dropdownColor: Colors.black,
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValueCorMoto = newValue!;
                    });
                  },
                  items: corMotos.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [],
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(10)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(color: Colors.black),
                        ),
                      ),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Finalizar Cadastro',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      if (validarDados()) {
                        inserirMotoca(
                                dataNascimento,
                                dropdownValueCidades,
                                _controllerTelefone.text,
                                _controllerCNH.text,
                                _controllerPlaca.text,
                                dropdownValueMarca,
                                dropdownValueAnoMoto,
                                dropdownValueCorMoto,
                                usuarioLogado)
                            .then((value) {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const InicioMotoca()),
                              (Route<dynamic> route) => false);
                        }).catchError((e) {
                          exibirToastTop(
                              "Erro ao tentar inserir seus dados, tente novamente mais tarde");
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  buscarUsuarioLogado() async {
    return FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        user.reload();
        usuarioLogado = user;
      } else {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
            (Route<dynamic> route) => false);
      }
    });
  }

  int calcularIdade() {
    var dataAtual = DateTime.now();
    int idade = dataAtual.year - dataNascimento.year;
    if (dataAtual.month < dataNascimento.month) {
      idade--;
    } else if (dataAtual.month == dataNascimento.month) {
      if (dataAtual.day < dataNascimento.day) idade--;
    }

    return idade;
  }

  bool validarDados() {
    if (calcularIdade() < 18) {
      exibirToastTop("Precisa ser maior que 18 anos");
      return false;
    }
    if (dropdownValueCidades == "Selecione a Cidade") {
      exibirToastTop("Preencha a sua cidade");
      return false;
    }
    if (_controllerTelefone.text.isEmpty ||
        _controllerTelefone.text.length != 19) {
      exibirToastTop("Preencha seu telefone");
      return false;
    }
    if (_controllerCNH.text.isEmpty || _controllerCNH.text.length < 10) {
      exibirToastTop("Preencha sua CNH");
      return false;
    }
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
