// import 'package:Motoca/Cliente/Singletons/corrida_singleton.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:Motoca/Cliente/controller/usuario_controller.dart';

Future buscarMarcas() async {
  CollectionReference motoca =
      FirebaseFirestore.instance.collection('MarcasMoto');
  var docs = await motoca.get();
  if (docs.size > 0) {
    return docs.docs;
  } else {
    return Future.error("Não existe marcas");
  }
}

Future buscarAnos() async {
  CollectionReference motoca =
      FirebaseFirestore.instance.collection('AnosMoto');
  var docs = await motoca.get();
  if (docs.size > 0) {
    return docs.docs;
  } else {
    return Future.error("Não existe anos");
  }
}

Future buscarCores() async {
  CollectionReference motoca =
      FirebaseFirestore.instance.collection('CoresMoto');
  var docs = await motoca.get();
  if (docs.size > 0) {
    return docs.docs;
  } else {
    return Future.error("Não existe cores");
  }
}
