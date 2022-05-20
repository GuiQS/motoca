import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Motoca/Cliente/controller/usuario_controller.dart';
import '../model/endereco.model.dart';

Future<DocumentReference<Object?>> inserirCorrida(
    User usuarioLogado,
    double preco,
    double km,
    Endereco endereco,
    String formaPagamento,
    String troco) async {
  CollectionReference corrida =
      FirebaseFirestore.instance.collection('Corridas');
  var userId = usuarioLogado.uid;

  var usuario = await verificarSeTemUsuario(userId);
  return await corrida.add({
    'nome': usuarioLogado.displayName,
    'email': usuarioLogado.email,
    'telefone': usuario['telefone'],
    'data': DateTime.now(),
    'preco': preco,
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
      .where('status', whereIn: ["procurando", "aceito"]).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return Future.error("Não existe corrida");
  }
}

Future verificarMotocaDisponivelNaCidade(String cidade) async {
  CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');
  var docs = await motoca
      .where('cidade', isEqualTo: cidade)
      .where('disponivel', isEqualTo: "sim")
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
      .where('status', whereIn: ["aceito"]).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return Future.error("Não existe corrida");
  }
}

Future buscarStatusCorridaPorId(String userId, String corridaId) async {
  var corrida = await FirebaseFirestore.instance
      .collection("Corridas")
      .doc(corridaId)
      .get();
  return corrida.get("status");
}

Future<bool> cancelarCorrida(String docId, String motivo) async {
  try {
    CollectionReference corrida =
        FirebaseFirestore.instance.collection('Corridas');
    await corrida.doc(docId).update({
      "status": "cancelado",
      "dataCancelamento": DateTime.now(),
      "motivoCancelamento": motivo
    });
    return true;
  } catch (e) {
    return false;
  }
}

Future buscarConfiguracaoCidade(String cidade) async {
  CollectionReference corrida =
      FirebaseFirestore.instance.collection('Cidades');
  var docs = await corrida.where('cidade', isEqualTo: cidade).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return Future.error("Não existe cidade");
  }
}
