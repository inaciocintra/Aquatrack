import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// Removendo imports de Firebase
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// import 'dart:async'; // StreamSubscription não é mais necessário
import 'settings_screen.dart'; // Importar para acessar globalDailyWaterGoal

// Variável global para armazenar a ingestão total de água do dia atual.
// ATENÇÃO: Esta variável será redefinida ao reiniciar o aplicativo.
double globalCurrentDayIntake = 0.0;
// Variável global para armazenar os registros de ingestão para os gráficos.
// Cada item será um Map<String, dynamic> com 'amount' (double) e 'timestamp' (DateTime)
// ATENÇÃO: Esta lista será redefinida ao reiniciar o aplicativo.
List<Map<String, dynamic>> globalWaterIntakeRecords = [];


class WaterIntakeHistory extends StatefulWidget {
  const WaterIntakeHistory({super.key});

  @override
  State<WaterIntakeHistory> createState() => _WaterIntakeHistoryState();
}

class _WaterIntakeHistoryState extends State<WaterIntakeHistory> {
  // Removendo instâncias de Firebase
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  // Removido _weeklyIntakeData pois o gráfico semanal será removido
  List<FlSpot> _monthlyIntakeData = [];
  double _dailyGoal = 0.0;
  double _currentDayIntake = 0.0;
  double _goalAchievementPercentage = 0.0;
  double _monthlyGoal = 0.0; // Nova variável para a meta mensal

  @override
  void initState() {
    super.initState();
    // Não precisamos mais de listeners de autenticação para dados locais
    _loadLocalData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadLocalData() {
    if (!mounted) return;

    // 1. Carregar Meta Diária
    _dailyGoal = globalDailyWaterGoal;

    // 2. Calcular Meta Mensal
    // Assumindo 30 dias para um cálculo simples da meta mensal
    _monthlyGoal = _dailyGoal * 30; // Ou DateUtils.getDaysInMonth(now.year, now.month)

    // 3. Carregar e Processar Registros de Ingestão
    _currentDayIntake = 0.0;
    _monthlyIntakeData = []; // Reinicia para o gráfico mensal

    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    Map<int, double> tempMonthlyDataMap = {}; // Key: day of month (1-31), Value: total intake for that day

    for (var record in globalWaterIntakeRecords) {
      final timestamp = record['timestamp'] as DateTime;
      final amount = record['amount'] as double;

      // Considerando o fuso horário de Brasília para os registros
      // (aqui, assumimos que o timestamp já foi salvo como DateTime.now() que é local)
      // Se você quiser tratar o timestamp como UTC e convertê-lo para Brasília para exibição,
      // a função _toBrasiliaTime() seria aplicada aqui.
      // Por simplicidade com dados locais, vamos usar o timestamp direto.
      
      // Para a ingestão do dia atual
      if (timestamp.day == now.day && timestamp.month == now.month && timestamp.year == now.year) {
        _currentDayIntake += amount;
      }

      // Para o gráfico mensal
      if (timestamp.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1)))) {
        tempMonthlyDataMap.update(timestamp.day, (value) => value + amount, ifAbsent: () => amount);
      }
    }

    // Converte o mapa mensal para FlSpot
    List<FlSpot> spots = [];
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    for (int i = 1; i <= daysInMonth; i++) {
      spots.add(FlSpot(i.toDouble(), tempMonthlyDataMap[i] ?? 0.0));
    }

    if (!mounted) return; // Checa se ainda está montado antes de setState

    setState(() {
      _monthlyIntakeData = spots;
      globalCurrentDayIntake = _currentDayIntake; // Atualiza a global de ingestão do dia
      _updateGoalAchievement(); // Atualiza a porcentagem
    });
  }

  // Função auxiliar para atualizar a porcentagem de conquista da meta diária
  void _updateGoalAchievement() {
    if (!mounted) return;
    setState(() {
      if (_dailyGoal > 0) {
        _goalAchievementPercentage = (_currentDayIntake / _dailyGoal) * 100;
        if (_goalAchievementPercentage > 100) _goalAchievementPercentage = 100; // Limita a 100%
      } else {
        _goalAchievementPercentage = 0.0;
      }
    });
  }

  
  DateTime _toBrasiliaTime(DateTime inputTime) {
    
    return inputTime; 
  }


  Future<void> _recordWaterIntake() async {
    TextEditingController _waterAmountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registrar Ingestão de Água'),
          content: TextField(
            controller: _waterAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade (ml)',
              hintText: 'Ex: 200',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Registrar'),
              onPressed: () {
                final double? amount = double.tryParse(_waterAmountController.text);
                if (amount != null && amount > 0) {
                  
                  globalWaterIntakeRecords.add({
                    'amount': amount / 1000, // Salva em litros
                    'timestamp': DateTime.now(), // Usa DateTime.now() local para o registro
                  });
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingestão de água registrada!')),
                  );
                  _loadLocalData(); // Recarrega os dados após registrar
                  Navigator.of(context).pop();
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, insira uma quantidade válida.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _recordWaterIntake();
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Histórico de Ingestão de Água',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              if (_dailyGoal > 0)
                Center(
                  child: Text(
                    'Meta Diária: ${_dailyGoal.toStringAsFixed(2)} Litros',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              if (_currentDayIntake > 0 || _dailyGoal > 0)
                Center(
                  child: Text(
                    'Ingestão Hoje: ${_currentDayIntake.toStringAsFixed(2)} Litros',
                    style: const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              const SizedBox(height: 20),
              // REMOVIDO: Gráfico Semanal
              // const Text('Ingestão Semanal', style: TextStyle(fontWeight: FontWeight.bold)),
              // const SizedBox(height: 8),
              // Expanded(child: _buildBarChart()),
              // const SizedBox(height: 20),

              const Text('Conquista da Meta Diária', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(height: 150, child: _buildPieChart()),
              const SizedBox(height: 20),

              const Text('Progresso Mensal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(child: _buildLineChart()), // Usar Expanded para o gráfico mensal
            ],
          ),
        ),
      ),
    );
  }

  // REMOVIDO: Widget _buildBarChart()
  // @override
  // Widget _buildBarChart() { /* ... */ }

  Widget _buildPieChart() {
    // Para que a porcentagem seja exibida sem muitas casas decimais
    String percentageText = '${_goalAchievementPercentage.toStringAsFixed(0)}%';

    return PieChart(
      PieChartData(
        sections: [
          // Conquista da meta
          PieChartSectionData(
            value: _goalAchievementPercentage,
            color: Colors.blue,
            title: percentageText, // Usando a string formatada
            radius: 50,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          // Parte restante para 100%
          PieChartSectionData(
            value: 100 - _goalAchievementPercentage,
            color: Colors.grey.shade300,
            title: '', // Não exibe título para a parte restante
            radius: 45,
            titleStyle: const TextStyle(fontSize: 0), // Garante que não haja texto
          ),
        ],
        centerSpaceRadius: 40,
        sectionsSpace: 0,
      ),
    );
  }

  Widget _buildLineChart() {
    // Calculando a ingestão mensal total
    double totalMonthlyIntake = _monthlyIntakeData.map((spot) => spot.y).fold(0.0, (sum, y) => sum + y);

    // Definir o maxY para o gráfico de linha, considerando a meta mensal
    // ou a ingestão máxima para garantir que o gráfico se ajuste.
    double maxLineY = _monthlyGoal > 0 ? _monthlyGoal * 1.1 : 0; // 10% acima da meta mensal
    if (totalMonthlyIntake * 1.1 > maxLineY) {
      maxLineY = totalMonthlyIntake * 1.1;
    }
    if (maxLineY < 2) maxLineY = 2; // Garante um mínimo para o gráfico

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          horizontalInterval: maxLineY / 4, // Intervalo baseado no maxY
          drawVerticalLine: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Exibe os rótulos do eixo Y
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}L',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Exibe os dias do mês
                if (value % 5 == 0 || value == 1 || value.toInt() == DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month)) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Dia ${value.toInt()}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        minX: 1,
        maxX: DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month).toDouble(),
        minY: 0,
        maxY: maxLineY, // Usa o maxY calculado
        lineBarsData: [
          LineChartBarData(
            spots: _monthlyIntakeData,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
            dotData: FlDotData(
              show: false,
            ),
          ),
          // Linha da Meta Mensal
          if (_monthlyGoal > 0)
            LineChartBarData(
              spots: [
                FlSpot(1, _monthlyGoal),
                FlSpot(DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month).toDouble(), _monthlyGoal),
              ],
              isCurved: false,
              color: Colors.green, // Cor da linha da meta
              barWidth: 1,
              dashArray: [5, 5], // Linha tracejada
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
      ),
    );
  }
}