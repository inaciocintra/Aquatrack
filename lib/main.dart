import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'telalogin.dart';

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
    home: const telalogin(),
    debugShowCheckedModeBanner: false,
  ));
}
