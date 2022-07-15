import 'package:Motoca/Cliente/Singletons/corrida_singleton.dart';
import 'package:Motoca/Motoca/Singletons/motoca_singleton.dart';
import 'package:Motoca/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Motoca/Cliente/controller/usuario_controller.dart';
import '../model/endereco.model.dart';

Future<dynamic> inserirCorrida(
  User usuarioLogado,
  double preco,
  double km,
  Endereco endereco,
  String formaPagamento,
  String troco,
) async {
  bool cidadeDisponivel = await verificarSeCidadeTaDisponivel(endereco.cidade);
  if (!cidadeDisponivel) {
    return Future.error("Cidade está fechada");
  }

  CollectionReference corrida =
      FirebaseFirestore.instance.collection('Corridas');
  var userId = usuarioLogado.uid;

  var usuario = await verificarSeTemUsuario(userId);
  return await corrida.add({
    'nome': usuarioLogado.displayName,
    'email': usuarioLogado.email,
    'telefone': usuario['telefone'],
    'data': FieldValue.serverTimestamp(),
    'preco': preco.toStringAsFixed(2),
    'km': km,
    'endereco': endereco.toJson(),
    'userId': userId,
    'status': 'procurando',
    'formaPagamento': formaPagamento,
    'troco': troco,
  });
}

Future verificarSeTemCorrida(String userId) async {
  CollectionReference corrida =
      FirebaseFirestore.instance.collection('Corridas');
  var docs = await corrida
      .where('userId', isEqualTo: userId)
      .where('status', whereIn: ["procurando", "aceito", "andamento"]).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return Future.error("Não existe corrida");
  }
}

// Future verificarMotocaDisponivelNaCidade(String cidade) async {
//   CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');
//   var docs = await motoca
//       .where('cidade', isEqualTo: cidade)
//       .where('disponivel', isEqualTo: "sim")
//       .get();
//   if (docs.size > 0) {
//     return true;
//   } else {
//     return false;
//   }
// }

Future verificarSeCidadeTaDisponivel(String cidade) async {
  CollectionReference cidades =
      FirebaseFirestore.instance.collection('Cidades');
  var docs = await cidades
      .where('cidade', isEqualTo: cidade)
      .where('status', isEqualTo: "aberta")
      .get();
  if (docs.size > 0) {
    return true;
  } else {
    return false;
  }
}

Future buscarCorridaAtual(String userId) async {
  CollectionReference corrida =
      FirebaseFirestore.instance.collection('Corridas');
  var docs = await corrida
      .where('userId', isEqualTo: userId)
      .where('status', whereIn: ["aceito", "andamento"]).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return null;
  }
}

Future<dynamic> buscarCorridaPorId(String corridaId) async {
  var corrida = await FirebaseFirestore.instance
      .collection("Corridas")
      .doc(corridaId)
      .get();
  return corrida;
}

Future<dynamic> buscarCorridaAtivaMotoca(String motocaId) async {
  var corrida = await FirebaseFirestore.instance
      .collection("Corridas")
      .where("motoca.userId", isEqualTo: motocaId)
      .where("status", whereIn: ["aceito", "andamento"]).get();
  if (corrida.size > 0) {
    return corrida.docs.first;
  } else {
    return Future.error("Não tem corrida ativa");
  }
}

Future<dynamic> buscarCorridasUsuario(
    String userId,
    List<String> status,
    bool filtrarCanceladoPorAdm,
    bool canceladoPorAdm,
    int limit,
    DateTime dataInicio,
    DateTime dataFim) async {
  if (filtrarCanceladoPorAdm) {
    return await FirebaseFirestore.instance
        .collection("Corridas")
        .where("userId", isEqualTo: userId)
        .where("cancelamentoAdministrativo", isEqualTo: canceladoPorAdm)
        .where('data', isGreaterThanOrEqualTo: dataInicio)
        .where('data', isLessThanOrEqualTo: dataFim)
        .limit(limit)
        .orderBy('data', descending: true)
        .get();
  } else {
    return await FirebaseFirestore.instance
        .collection("Corridas")
        .where("userId", isEqualTo: userId)
        .where("status", whereIn: status)
        .where('data', isGreaterThanOrEqualTo: dataInicio)
        .where('data', isLessThanOrEqualTo: dataFim)
        .limit(limit)
        .orderBy('data', descending: true)
        .get();
  }
  // return corrida.docs.toList();
}

Future<dynamic> buscarCorridasMotoca(
    String userId,
    List<String> status,
    bool filtrarCanceladoPorAdm,
    bool canceladoPorAdm,
    int limit,
    DateTime dataInicio,
    DateTime dataFim) async {
  if (filtrarCanceladoPorAdm) {
    return await FirebaseFirestore.instance
        .collection("Corridas")
        .where("motoca.userId", isEqualTo: userId)
        .where("cancelamentoAdministrativo", isEqualTo: canceladoPorAdm)
        .where('data', isGreaterThanOrEqualTo: dataInicio)
        .where('data', isLessThanOrEqualTo: dataFim)
        .limit(limit)
        .orderBy('data', descending: true)
        .get();
  } else {
    return await FirebaseFirestore.instance
        .collection("Corridas")
        .where("motoca.userId", isEqualTo: userId)
        .where("status", whereIn: status)
        .where('data', isGreaterThanOrEqualTo: dataInicio)
        .where('data', isLessThanOrEqualTo: dataFim)
        .limit(limit)
        .orderBy('data', descending: true)
        .get();
  }
}

Future<List<dynamic>> buscarCorridasFinalizadasUsuario(
    String userId, DateTime dataInicio, DateTime dataFim) async {
  var corrida = await FirebaseFirestore.instance
      .collection("Corridas")
      .where("userId", isEqualTo: userId)
      .where("status", isEqualTo: "finalizado")
      .where('data', isLessThanOrEqualTo: dataFim)
      .where('data', isGreaterThanOrEqualTo: dataInicio)
      .get();
  return corrida.docs.toList();
}

Future<List<dynamic>> buscarCorridasFinalizadasMotoca(
    String userId, DateTime dataInicio, DateTime dataFim) async {
  var corrida = await FirebaseFirestore.instance
      .collection("Corridas")
      .where("motoca.userId", isEqualTo: userId)
      .where("status", isEqualTo: "finalizado")
      .where('data', isLessThanOrEqualTo: dataFim)
      .where('data', isGreaterThanOrEqualTo: dataInicio)
      .get();
  return corrida.docs.toList();
}

Future<bool> cancelarCorrida(String motivo) async {
  var corridaAtual =
      await buscarCorridaAtual(SingletonCorrida.instance.getUsuarioId());
  try {
    if (corridaAtual != null) {
      var idMotoca = corridaAtual["motoca"]["userId"];
      var dataInicioCorrida = DateTime.fromMicrosecondsSinceEpoch(
          corridaAtual["dataInicioCorrida"].millisecondsSinceEpoch * 1000);

      Timestamp tempoDestino = corridaAtual["tempoDestino"];
      DateTime tempoAteChegarOMotoca = DateTime.fromMicrosecondsSinceEpoch(
          tempoDestino.millisecondsSinceEpoch * 1000);
      if (DateTime.now().isBefore(tempoAteChegarOMotoca)) {
        if (dataInicioCorrida
            .add(Duration(
                minutes: int.parse(SingletonCorrida.instance
                    .getTempoMinimoMinutoParaCancelarCorrida())))
            .isBefore(DateTime.now())) {
          return Future.error(
              "Já passou o tempo minimo para o cancelamento da corrida");
        }
      }

      // if (idMotoca != "") {
      //   await alterarStatusMotoca(idMotoca, "sim");
      // }
    }
    CollectionReference corrida =
        FirebaseFirestore.instance.collection('Corridas');
    await corrida.doc(SingletonCorrida.instance.getCorridaId()).update({
      "status": "cancelado",
      "dataCancelamento": FieldValue.serverTimestamp(),
      "motivoCancelamento": motivo,
      "cancelamentoAdministrativo": false
    });
    return true;
  } catch (e) {
    return Future.error("Erro ao tentar cancelar a corrida");
  }
}

Future<bool> cancelarCorridaMotoca(String motivo, String motocaId) async {
  var corridaAtual =
      await buscarCorridaAtivaMotoca(SingletonMotoca.instance.getUsuarioId());

  // await alterarStatusMotoca(motocaId, "sim");

  try {
    CollectionReference corrida =
        FirebaseFirestore.instance.collection('Corridas');
    await corrida.doc(corridaAtual.id).update({
      "status": "cancelado",
      "dataCancelamento": FieldValue.serverTimestamp(),
      "motivoCancelamento": motivo,
      "cancelamentoAdministrativo": true
    });

    return true;
  } catch (e) {
    return Future.error("Erro ao tentar cancelar a corrida");
  }
}

// Future<bool> alterarStatusMotoca(String docId, String status) async {
//   try {
//     CollectionReference corrida =
//         FirebaseFirestore.instance.collection('Motoca');
//     await corrida.doc(docId).update({
//       "disponivel": status,
//     });
//     return true;
//   } catch (e) {
//     return false;
//   }
// }

Future buscarConfiguracaoCidade(String cidade) async {
  CollectionReference cidades =
      FirebaseFirestore.instance.collection('Cidades');
  var docs = await cidades.where('cidade', isEqualTo: cidade).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return Future.error("Não existe cidade");
  }
}

Future atribuirMotoca(String corridaId, dynamic motoca, DateTime tempoDestino,
    double porcentagemAdm) async {
  var corrida = await buscarCorridaPorId(corridaId);
  if (corrida["status"] != "procurando") {
    exibirToastTop("Essa corrida já foi pega por outro motoca");
    return;
  }
  var repasse =
      ((double.parse(corrida["preco"]) * porcentagemAdm)).toStringAsFixed(2);

  CollectionReference corridas =
      FirebaseFirestore.instance.collection('Corridas');
  await corridas.doc(corridaId).update({
    "status": "aceito",
    "motoca": motoca,
    "dataInicioCorrida": FieldValue.serverTimestamp(),
    "tempoDestino": tempoDestino,
    "cancelamentoAdministrativo": false,
    "repasse": repasse,
  });
}

Future iniciarCorrida(String corridaId) async {
  CollectionReference corridas =
      FirebaseFirestore.instance.collection('Corridas');
  await corridas.doc(corridaId).update({
    "status": "andamento",
    "dataCorridaIniciada": FieldValue.serverTimestamp(),
  });
}

Future finalizarCorrida(String corridaId) async {
  CollectionReference corridas =
      FirebaseFirestore.instance.collection('Corridas');
  await corridas.doc(corridaId).update({
    "status": "finalizado",
    "dataCorridaFinalizada": FieldValue.serverTimestamp(),
  });
}
