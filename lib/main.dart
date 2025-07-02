import 'package:flutter/material.dart'; // Importar Material design
import 'package:firebase_core/firebase_core.dart'; // Importar Firebase Core
import 'package:flutter_localizations/flutter_localizations.dart'; // Importar localizações do Flutter
import 'firebase_options.dart';
import 'telalogin.dart'; // Certifique-se de que 'telalogin.dart' está no mesmo diretório ou caminho correto

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
    title: 'Aquatrack',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const telalogin(), // Certifique-se de que telalogin é uma classe com construtor constante, ou remova 'const' se ela não for
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en', ''), // English, no country code
      Locale('pt', 'BR'), // Portuguese, Brazil
    ],
  ));
}