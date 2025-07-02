import 'package:flutter/material.dart';
// Removendo imports de Firebase para esta funcionalidade
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'water_intake_history.dart'; // Importar WaterIntakeHistory

// Variável global para armazenar a meta diária.
// ATENÇÃO: Esta variável será redefinida ao reiniciar o aplicativo.
double globalDailyWaterGoal = 0.0;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? _displayDailyWaterGoal; // Para exibir a meta calculada na tela
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Carregar a meta global e exibir, se houver
    _displayDailyWaterGoal = globalDailyWaterGoal.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Função para calcular e armazenar a meta diária de água 
  Future<void> _calculateAndSaveDailyWaterIntake() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _displayDailyWaterGoal = null;
    });

    final double? weight = double.tryParse(_weightController.text);
    final double? height = double.tryParse(_heightController.text);

    if (weight == null || height == null) {
      setState(() {
        _errorMessage = "Por favor, preencha o Peso e a Altura.";
        _isLoading = false;
      });
      return;
    }

    // Calcula a meta diária de água com base no peso e altura
    // Exemplo: 35ml por kg de peso + um ajuste de 5ml por cm de altura
    // Ajuste a fórmula conforme sua necessidade.
    double calculatedWaterGoal = (weight * 0.035) + (height * 0.005);
    
    setState(() {
      _displayDailyWaterGoal = calculatedWaterGoal.toStringAsFixed(2);
      globalDailyWaterGoal = calculatedWaterGoal; // Salva na variável global
      _isLoading = false;
    });

    // Removido o código de salvamento no Firebase Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meta de água calculada e salva!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                title: const Text("Notificações para lembrar de beber Água"),
                value: true,
                onChanged: (bool value) {},
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  hintText: 'Ex: 70',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Altura (cm)',
                  hintText: 'Ex: 175',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isLoading ? null : _calculateAndSaveDailyWaterIntake,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Calcular e Salvar Meta de Água",
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 20),

              if (_displayDailyWaterGoal != null && !_isLoading)
                Card(
                  elevation: 2,
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.only(top: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        const Text(
                          "Meta Diária de Água Calculada:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_displayDailyWaterGoal Litros',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WaterIntakeHistory()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
        ],
      ),
    );
  }
}