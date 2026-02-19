import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _TransacaoResumo {
  final double totalGanhos;
  final double totalGastos;

  _TransacaoResumo({required this.totalGanhos, required this.totalGastos});

  double get saldo => totalGanhos - totalGastos;
}

class GraficosCarrosselWidget extends StatefulWidget {
  const GraficosCarrosselWidget({super.key});

  @override
  State<GraficosCarrosselWidget> createState() =>
      GraficosCarrosselWidgetState();
}

class GraficosCarrosselWidgetState extends State<GraficosCarrosselWidget> {
  bool _carregando = true;

  _TransacaoResumo? _resumoHoje;
  _TransacaoResumo? _resumoSemana;
  _TransacaoResumo? _resumoMes;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // ===========================================================
  // 🔓 MÉTODO PÚBLICO (chamado pela HomeScreen via GlobalKey)
  // ===========================================================
  Future<void> carregarDados() async {
    await _carregarDados();
  }

  // ===========================================================
  // 🔒 MÉTODO PRIVADO
  // ===========================================================
  Future<void> _carregarDados() async {
    try {
      final agora = DateTime.now();

      // ===== HOJE =====
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final fimHoje = hoje.add(const Duration(days: 1));

      // ===== SEMANA (segunda → próxima segunda) =====
      final inicioSemana = hoje.subtract(Duration(days: hoje.weekday - 1));
      final fimSemana = inicioSemana.add(const Duration(days: 7));

      // ===== MÊS =====
      final inicioMes = DateTime(agora.year, agora.month, 1);
      final fimMes = DateTime(agora.year, agora.month + 1, 1);

      final resumoHoje = await _resumirPeriodo(hoje, fimHoje);
      final resumoSemana = await _resumirPeriodo(inicioSemana, fimSemana);
      final resumoMes = await _resumirPeriodo(inicioMes, fimMes);

      debugPrint(
        '📊 Hoje → G:${resumoHoje.totalGanhos} | Gastos:${resumoHoje.totalGastos}',
      );
      debugPrint(
        '📊 Semana → G:${resumoSemana.totalGanhos} | Gastos:${resumoSemana.totalGastos}',
      );
      debugPrint(
        '📊 Mês → G:${resumoMes.totalGanhos} | Gastos:${resumoMes.totalGastos}',
      );

      if (!mounted) return;

      setState(() {
        _resumoHoje = resumoHoje;
        _resumoSemana = resumoSemana;
        _resumoMes = resumoMes;
        _carregando = false;
      });
    } catch (e, stack) {
      debugPrint('❌ Erro ao carregar gráficos: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  // ===========================================================
  // 🔹 FIRESTORE
  // ===========================================================
  Future<_TransacaoResumo> _resumirPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    double ganhos = 0;
    double gastos = 0;

    final ganhosSnapshot = await FirebaseFirestore.instance
        .collection('ganhos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .get();

    for (final doc in ganhosSnapshot.docs) {
      ganhos += _parseValor(doc.data()['valor']);
    }

    final gastosSnapshot = await FirebaseFirestore.instance
        .collection('gastos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .get();

    for (final doc in gastosSnapshot.docs) {
      gastos += _parseValor(doc.data()['valor']);
    }

    return _TransacaoResumo(totalGanhos: ganhos, totalGastos: gastos);
  }

  double _parseValor(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String) {
      final limpo = valor
          .replaceAll(RegExp(r'[^\d,.]'), '')
          .replaceAll(',', '.');
      return double.tryParse(limpo) ?? 0;
    }
    return 0;
  }

  // ===========================================================
  // UI
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const SizedBox(
        height: 260,
        child: Card(
          margin: EdgeInsets.all(8),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 240,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
        ),
        items: [
          _criarCardGrafico(_resumoHoje!, 'Hoje'),
          _criarCardGrafico(_resumoSemana!, 'Esta semana'),
          _criarCardGrafico(_resumoMes!, 'Este mês'),
        ],
      ),
    );
  }

  Widget _criarCardGrafico(_TransacaoResumo resumo, String titulo) {
    if (resumo.totalGanhos == 0 && resumo.totalGastos == 0) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Icon(Icons.info_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Nenhum dado registrado neste período.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: resumo.totalGanhos,
                          color: Colors.green,
                          width: 22,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: resumo.totalGastos,
                          color: Colors.red,
                          width: 22,
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          if (value == 0) return const Text('Ganhos');
                          if (value == 1) return const Text('Gastos');
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ganhos: R\$ ${resumo.totalGanhos.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.green),
            ),
            Text(
              'Gastos: R\$ ${resumo.totalGastos.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red),
            ),
            Text(
              'Saldo: R\$ ${resumo.saldo.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: resumo.saldo >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
