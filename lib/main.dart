import 'package:Motoca/Motoca/controller/motoca_controller.dart';
import 'package:Motoca/Motoca/inicioMotoca.dart';
import 'package:flutter/material.dart';
import 'package:Motoca/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Motoca/Cliente/inicioCliente.dart';
import 'package:Motoca/util.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_button/sign_button.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

FirebaseAuth auth = FirebaseAuth.instance;
TextEditingController controllerCodigo = TextEditingController();
bool ehMotoca = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAuth.instance.setLanguageCode("pt");
  runApp(const MyApp());
}

validarAutenticacao(context) {
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      buscarPerfilMotoca(user.uid).then((value) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InicioMotoca()),
            (Route<dynamic> route) => false);
      }).catchError((e) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InicioClient()),
            (Route<dynamic> route) => false);
      });
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: const [Locale('pt', 'BR')],
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
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("../assets/images/logo.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: const [
            //     Icon(
            //       Icons.motorcycle,
            //       color: Colors.greenAccent,
            //       size: 120,
            //     ),
            //   ],
            // ),
            // Image.asset(
            //   'assets/icon.png',
            // ),
            // Image.network(
            //   "https://i.pinimg.com/736x/e4/9f/f0/e49ff0cb6dc43f46c570b83f5cedce2f.jpg",
            //   fit: BoxFit.cover,
            // ),
            // const Image(image: AssetImage("assets/icon.png")),
            const SizedBox(
              height: 10,
            ),
            SignInButton(
                buttonType: ButtonType.google,
                btnText: "Entrar com o Google",
                buttonSize: ButtonSize.large,
                onPressed: () {
                  signInWithGoogle();
                }),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: TextButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      const EdgeInsets.all(5)),
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
                    Icon(
                      Icons.motorcycle,
                      color: Colors.black,
                      size: 40,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Sou Motoca',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    ehMotoca = true;
                  });
                  signInWithGoogle();
                },
              ),
            ),
          ],
        ),
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
}
