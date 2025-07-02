import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController(); // Novo controlador para altura

  bool _isPasswordVisible = false;
  bool _isEmailNotification = false;
  bool _isPhoneNotification = false;
  bool _isMale = true;

  Future<void> _cadastrar() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _senhaController.text.trim());

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
        'nome': _nomeController.text.trim(),
        'data_nascimento': _dataController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'email': _emailController.text.trim(),
        'genero': _isMale ? 'Masculino' : 'Feminino',
        'notifica_email': _isEmailNotification,
        'notifica_telefone': _isPhoneNotification,
        'altura': double.tryParse(_alturaController.text.trim()), // Salva a altura como double
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela de Cadastro')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: SizedBox(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome')),
                  const SizedBox(height: 16),
                  TextField(controller: _dataController, decoration: const InputDecoration(labelText: 'Data nascimento')),
                  const SizedBox(height: 16),
                  TextField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone')),
                  const SizedBox(height: 16),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _senhaController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _alturaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Altura (cm)'), // Novo campo de altura
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Masculino'),
                      Checkbox(
                        value: _isMale,
                        onChanged: (value) {
                          setState(() {
                            _isMale = value ?? true;
                          });
                        },
                      ),
                      const Text('Feminino'),
                      Checkbox(
                        value: !_isMale,
                        onChanged: (value) {
                          setState(() {
                            _isMale = !(value ?? true);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notificações por e-mail'),
                      Switch(
                        value: _isEmailNotification,
                        onChanged: (value) {
                          setState(() {
                            _isEmailNotification = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notificações por telefone'),
                      Switch(
                        value: _isPhoneNotification,
                        onChanged: (value) {
                          setState(() {
                            _isPhoneNotification = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cadastrar,
                    child: const Text('Cadastrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}