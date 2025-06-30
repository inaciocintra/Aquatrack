import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controladores para os campos de texto
  final TextEditingController _weightController = TextEditingController();

  // Variáveis para os seletores de nível de atividade e clima
  String? _selectedActivityLevel;
  String? _selectedClimate;

  // Variáveis para armazenar o resultado da API e o estado do carregamento/erro
  String? _dailyWaterIntake;
  bool _isLoading = false;
  String? _errorMessage;

  // Instância do Firebase Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Você pode carregar os dados do usuário do Firebase aqui ao iniciar a tela, se desejar
    _loadUserSettings();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // Função para carregar as configurações do usuário do Firebase
  Future<void> _loadUserSettings() async {
    try {
      // Supondo que você tenha um ID de usuário, ou que você esteja salvando
      // as configurações sob um documento fixo (ex: 'user_settings')
      // Para simplificar, vou usar um ID fixo 'currentUserSettings'
      // Em um app real, você usaria FirebaseAuth para obter o ID do usuário logado.
      DocumentSnapshot userSettings = await _firestore.collection('userSettings').doc('currentUserSettings').get();

      if (userSettings.exists) {
        Map<String, dynamic> data = userSettings.data() as Map<String, dynamic>;
        setState(() {
          _weightController.text = data['weight']?.toString() ?? '';
          _selectedActivityLevel = data['activityLevel'];
          _selectedClimate = data['climate'];
          _dailyWaterIntake = data['dailyWaterIntake']; // Exibe o último cálculo, se houver
        });
      }
    } catch (e) {
      print("Erro ao carregar configurações do usuário: $e");
      setState(() {
        _errorMessage = "Erro ao carregar configurações: $e";
      });
    }
  }


  // Função para chamar a API e calcular a ingestão diária de água
  Future<void> _calculateDailyWaterIntake() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _dailyWaterIntake = null;
    });

    final double? weight = double.tryParse(_weightController.text);

    if (weight == null || _selectedActivityLevel == null || _selectedClimate == null) {
      setState(() {
        _errorMessage = "Por favor, preencha todos os campos: Peso, Nível de Atividade e Clima.";
        _isLoading = false;
      });
      return;
    }

    // Mapeamento dos valores selecionados para os valores esperados pela API
    final String activityLevelApi = _selectedActivityLevel!.toLowerCase();
    final String climateApi = _selectedClimate!.toLowerCase();

    final String url =
        'https://health-calculator-api.p.rapidapi.com/dwi?weight=$weight&activity_level=$activityLevelApi&climate=$climateApi&unit=liters';
    final Map<String, String> headers = {
      'x-rapidapi-host': 'health-calculator-api.p.rapidapi.com',
      'x-rapidapi-key': '5189ad2817msh80714bb28d88228p14a2d6jsnc894cbd0cb31', // Sua chave da RapidAPI
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _dailyWaterIntake = data['daily_water_intake_liters']?.toStringAsFixed(2) ?? 'N/A';
          _isLoading = false;
          // Salvar os dados no Firebase após o cálculo bem-sucedido
          _saveUserSettings(weight, activityLevelApi, climateApi, _dailyWaterIntake!);
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao chamar a API: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro na requisição: $e';
        _isLoading = false;
      });
    }
  }

  // Função para salvar os dados do usuário no Firebase
  Future<void> _saveUserSettings(double weight, String activityLevel, String climate, String dailyWaterIntake) async {
    try {
      await _firestore.collection('userSettings').doc('currentUserSettings').set({
        'weight': weight,
        'activityLevel': activityLevel,
        'climate': climate,
        'dailyWaterIntake': dailyWaterIntake,
        'timestamp': FieldValue.serverTimestamp(), // Adiciona um timestamp da última atualização
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas com sucesso!')),
      );
    } catch (e) {
      print("Erro ao salvar configurações no Firebase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configurações: $e')),
      );
    }
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
              // Lembretes de água e Dark Mode (mantidos do seu código original)
              SwitchListTile(
                title: const Text("Water Intake Reminders"),
                value: true, // Você precisaria gerenciar o estado real aqui
                onChanged: (bool value) {
                  // Implementar lógica para ativar/desativar lembretes
                },
              ),
              SwitchListTile(
                title: const Text("Dark Mode"),
                value: true, // Você precisaria gerenciar o estado real aqui
                onChanged: (bool value) {
                  // Implementar lógica para ativar/desativar modo escuro
                },
              ),
              const SizedBox(height: 20),

              // Campo de entrada de Peso
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

              // Dropdown para Nível de Atividade
              DropdownButtonFormField<String>(
                value: _selectedActivityLevel,
                decoration: const InputDecoration(
                  labelText: 'Nível de Atividade',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Selecione seu nível de atividade'),
                items: <String>['sedentary', 'light', 'moderate', 'active']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)), // Capitaliza a primeira letra
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivityLevel = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Dropdown para Clima
              DropdownButtonFormField<String>(
                value: _selectedClimate,
                decoration: const InputDecoration(
                  labelText: 'Clima',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Selecione o clima'),
                items: <String>['normal', 'hot', 'cold']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)), // Capitaliza a primeira letra
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedClimate = newValue;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Botão para calcular e salvar
              ElevatedButton(
                onPressed: _isLoading ? null : _calculateDailyWaterIntake,
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
                        "Calcular e Salvar Ingestão de Água",
                        style: TextStyle(fontSize: 18),
                      ),
              ),
              const SizedBox(height: 20),

              // Exibição do resultado do cálculo ou mensagem de erro
              if (_dailyWaterIntake != null && !_isLoading)
                Card(
                  elevation: 2,
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.only(top: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        const Text(
                          "Ingestão Diária de Água Recomendada:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$_dailyWaterIntake Litros',
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
    );
  }
}