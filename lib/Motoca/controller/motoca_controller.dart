// import 'package:Motoca/Cliente/Singletons/corrida_singleton.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:Motoca/Motoca/Singletons/motoca_singleton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
// import 'package:Motoca/Cliente/controller/usuario_controller.dart';

Future buscarPerfilMotoca(String idMotoca) async {
  CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');
  var docs = await motoca.where('userId', isEqualTo: idMotoca).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return Future.error("Não existe o motoca");
  }
}

Future<dynamic> inserirMotoca(
  DateTime nascimento,
  String cidade,
  String telefone,
  String cnh,
  String placa,
  String marcaMoto,
  String anoMoto,
  String corMoto,
  User usuarioLogado,
) async {
  CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');

  return await motoca.add({
    'cidade': cidade,
    'bloqueado': 'nao',
    'telefone': telefone,
    'dataNascimento': nascimento,
    'dataCadastro': FieldValue.serverTimestamp(),
    'cnh': cnh,
    'userId': usuarioLogado.uid,
    'nomeCompleto': usuarioLogado.displayName,
    'contratosRecebendo': null,
    'contratosPagos': [],
    'email': usuarioLogado.email,
    'motos': [
      {
        'placa': placa,
        'marca': marcaMoto,
        'ano': anoMoto,
        'cor': corMoto,
        'id': const Uuid().v1(),
        'status': 'ativa'
      }
    ]
  });
}

inserirMoto(dynamic moto) async {
  CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');
  var docs = await motoca
      .where('userId', isEqualTo: SingletonMotoca.instance.getUsuarioId())
      .get();

  if (docs.size != 1) return Future.error("Erro ao tentar inserir moto");

  List<dynamic> motosMotoca = docs.docs.first["motos"];
  motosMotoca.add(moto);

  await motoca.doc(docs.docs.first.id).update({
    "motos": motosMotoca,
  });
}

atualizarMoto(dynamic moto) async {
  CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');
  var docs = await motoca
      .where('userId', isEqualTo: SingletonMotoca.instance.getUsuarioId())
      .get();

  if (docs.size != 1) return Future.error("Erro ao tentar atualizar moto");

  List<dynamic> motosMotoca = docs.docs.first["motos"];

  for (var i = 0; i < motosMotoca.length; i++) {
    if (motosMotoca[i]["id"] == moto["id"]) {
      motosMotoca[i] = moto;
    }
  }

  await motoca.doc(docs.docs.first.id).update({
    "motos": motosMotoca,
  });
}

excluirMoto(String idMoto) async {
  CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');
  var docs = await motoca
      .where('userId', isEqualTo: SingletonMotoca.instance.getUsuarioId())
      .get();

  if (docs.size != 1) return Future.error("Erro ao tentar excluir moto");

  List<dynamic> novasMotos = <dynamic>[];
  List<dynamic> motosMotoca = docs.docs.first["motos"];

  for (var element in motosMotoca) {
    if (element["id"] != idMoto) {
      novasMotos.add(element);
    }
  }

  await motoca.doc(docs.docs.first.id).update({
    "motos": novasMotos,
  });
}

ativarMotoMotoca(String idMoto) async {
  CollectionReference motoca = FirebaseFirestore.instance.collection('Motoca');
  var docs = await motoca
      .where('userId', isEqualTo: SingletonMotoca.instance.getUsuarioId())
      .get();

  if (docs.size != 1) return Future.error("Erro ao tentar excluir moto");

  List<dynamic> motosMotoca = docs.docs.first["motos"];

  for (var element in motosMotoca) {
    if (element["id"] == idMoto) {
      element["status"] = "ativa";
    } else {
      element["status"] = "desativada";
    }
  }

  await motoca.doc(docs.docs.first.id).update({
    "motos": motosMotoca,
  });
}
