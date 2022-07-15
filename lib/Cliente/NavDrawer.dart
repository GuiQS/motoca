import 'package:Motoca/Cliente/Singletons/Singletons_nav.dart';
import 'package:Motoca/Cliente/Singletons/corrida_singleton.dart';
import 'package:Motoca/Cliente/corridas.dart';
import 'package:Motoca/Cliente/extrato.dart';
import 'package:Motoca/Cliente/inicioCliente.dart';
import 'package:Motoca/Cliente/model/usuario.model.dart';
import 'package:Motoca/Cliente/controller/corrida_controller.dart';
import 'package:Motoca/Motoca/inicioMotoca.dart';
import 'package:Motoca/main.dart';
import 'package:Motoca/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:package_info/package_info.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({Key? key}) : super(key: key);

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  Usuario usuario = Usuario();
  String versao = "";

  @override
  void initState() {
    usuario.nome = FirebaseAuth.instance.currentUser?.displayName ?? "";
    usuario.email = FirebaseAuth.instance.currentUser?.email ?? "";
    usuario.foto = FirebaseAuth.instance.currentUser?.photoURL ?? "";
    pegarVersaoApp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usuario.nome,
                      style: const TextStyle(fontSize: 20),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image(
                        image: NetworkImage(usuario.foto),
                        fit: BoxFit.fill,
                        width: 50,
                      ),
                    ),
                  ],
                ),
                Text(
                  usuario.email,
                  style: const TextStyle(fontSize: 12),
                ),
                const Divider(),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const InicioClient()),
                  (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_outlined),
            title: const Text('Histórico de Corridas'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Corridas()),
                  (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_outlined),
            title: const Text('Extrato de Corridas'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const Extrato()),
                  (Route<dynamic> route) => false);
            },
          ),
          ListTile(
            leading: const Icon(Icons.motorcycle),
            title: const Text('Sou Motoca'),
            onTap: () async {
              if (SingletonCorrida.instance.getCorridaAtiva()) {
                exibirToastTop("Existe corrida ativa");
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const InicioMotoca()),
                    (Route<dynamic> route) => false);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () async {
              if (SingletonCorrida.instance.getCorridaAtiva()) {
                await logoutCorridaAtiva();
              } else {
                FirebaseAuth.instance.signOut();

                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyApp()),
                    (Route<dynamic> route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  logoutCorridaAtiva() async {
    await Alert(
      context: context,
      style: const AlertStyle(backgroundColor: Colors.white),
      title: "Sua corrida será cancelada, deseja realmente sair do motoca?",
      buttons: [
        DialogButton(
          color: Colors.red,
          child: const Text(
            "Não",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          onPressed: () {
            Navigator.of(SingletonNav.instance.getContext()).pop();
          },
        ),
        DialogButton(
          color: Colors.greenAccent,
          child: const Text(
            "Sim",
            style: TextStyle(
              color: Colors.black,
            ),
          ),
          onPressed: () async {
            try {
              await cancelarCorrida("Cancelado automaticamente por logout");

              FirebaseAuth.instance.signOut();

              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyApp()),
                  (Route<dynamic> route) => false);
            } catch (e) {
              exibirToastTop(e.toString());
              Navigator.of(SingletonNav.instance.getContext()).pop();
            }
          },
        ),
      ],
    ).show();
  }

  pegarVersaoApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      versao = packageInfo.version;
    });
  }
}
