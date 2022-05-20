import 'package:Motoca/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Motoca/Cliente/inicioCliente.dart';
import 'package:Motoca/util.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info/package_info.dart';

FirebaseAuth auth = FirebaseAuth.instance;
TextEditingController controllerCodigo = TextEditingController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAuth.instance.setLanguageCode("pt");
  runApp(const MyApp());
}

validarAutenticacao(context) {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const InicioClient()),
          (Route<dynamic> route) => false);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motoca',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'Motoca'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String versao = "";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      validarAutenticacao(context);
      await pegarVersaoApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title),
            const Icon(
              Icons.motorcycle,
              color: Colors.white,
              size: 40.0,
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Entre agora em sua conta :)",
              style: GoogleFonts.aBeeZee(fontSize: 22, letterSpacing: .5),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Center(
            child: SignInButton(
              Buttons.Google,
              text: "Entrar",
              onPressed: () {
                signInWithGoogle();
              },
            ),
          ),
        ],
      ),
      bottomSheet: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Versão: " + versao),
        ],
      ),
    );
  }

  signInWithGoogle() async {
    try {
      GoogleSignIn _googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      msgError();
    }
  }

  msgError() async {
    exibirToastTop("Erro ao tentar entrar em sua conta");
  }

  pegarVersaoApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      versao = packageInfo.version;
    });
  }
}
