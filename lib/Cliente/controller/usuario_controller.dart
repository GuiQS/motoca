import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<dynamic> inserirTelefoneUsuario(User usuarioLogado, telefone) async {
  CollectionReference corrida =
      FirebaseFirestore.instance.collection('Usuarios');
  var userId = usuarioLogado.uid;
  return await corrida.add({
    'telefone': telefone,
    'userId': userId,
  });
}

Future verificarSeTemUsuario(String userId) async {
  CollectionReference corrida =
      FirebaseFirestore.instance.collection('Usuarios');
  var docs = await corrida.where('userId', isEqualTo: userId).get();
  if (docs.size > 0) {
    return docs.docs.first;
  } else {
    return Future.error("Usuário não encontrado");
  }
}
