// import 'package:Motoca/Cliente/Singletons/corrida_singleton.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:Motoca/Cliente/controller/usuario_controller.dart';

Future buscarRaiosController() async {
  CollectionReference raios = FirebaseFirestore.instance.collection('Raios');
  var docs = await raios.get();
  if (docs.size > 0) {
    return docs.docs;
  } else {
    return Future.error("Não existe cidades");
  }
}
