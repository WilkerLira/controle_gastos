// lib/widgets/graficos_carrossel_widget.dart

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
      _GraficosCarrosselWidgetState();
}

class _GraficosCarrosselWidgetState extends State<GraficosCarrosselWidget> {
  bool _carregando = true;
  _TransacaoResumo? _resumoHoje;
  _TransacaoResumo? _resumoSemana;
  _TransacaoResumo? _resumoMes;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<_TransacaoResumo> _resumirPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    double ganhos = 0;
    double gastos = 0;

    // Ganhos
    final ganhosSnapshot = await FirebaseFirestore.instance
        .collection('ganhos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .get();

    for (var doc in ganhosSnapshot.docs) {
      final data = doc.data();
      final valor = data['valor'];
      if (valor is num) {
        ganhos += valor.toDouble();
      } else if (valor is String) {
        final limpo = valor
            .replaceAll(RegExp(r'[^\d,.]'), '')
            .replaceAll(',', '.');
        final v = double.tryParse(limpo);
        if (v != null) ganhos += v;
      }
    }

    // Gastos
    final gastosSnapshot = await FirebaseFirestore.instance
        .collection('gastos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .get();

    for (var doc in gastosSnapshot.docs) {
      final data = doc.data();
      final valor = data['valor'];
      if (valor is num) {
        gastos += valor.toDouble();
      } else if (valor is String) {
        final limpo = valor
            .replaceAll(RegExp(r'[^\d,.]'), '')
            .replaceAll(',', '.');
        final v = double.tryParse(limpo);
        if (v != null) gastos += v;
      }
    }

    return _TransacaoResumo(totalGanhos: ganhos, totalGastos: gastos);
  }

  Future<void> _carregarDados() async {
    try {
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      final inicioSemana = hoje.subtract(
        Duration(days: hoje.weekday - 1),
      ); // Segunda
      final inicioMes = DateTime(agora.year, agora.month, 1);

      final fimHoje = hoje.add(const Duration(days: 1));
      final fimSemana = hoje.add(const Duration(days: 1));
      final fimMes = DateTime(agora.year, agora.month + 1, 1);

      final resumoHoje = await _resumirPeriodo(hoje, fimHoje);
      final resumoSemana = await _resumirPeriodo(inicioSemana, fimSemana);
      final resumoMes = await _resumirPeriodo(inicioMes, fimMes);

      // 🔍 Remova estas linhas depois do teste
      print(
        '✅ Hoje → G: ${resumoHoje.totalGanhos}, Gastos: ${resumoHoje.totalGastos}',
      );
      print(
        '✅ Semana → G: ${resumoSemana.totalGanhos}, Gastos: ${resumoSemana.totalGastos}',
      );
      print(
        '✅ Mês → G: ${resumoMes.totalGanhos}, Gastos: ${resumoMes.totalGastos}',
      );

      setState(() {
        _resumoHoje = resumoHoje;
        _resumoSemana = resumoSemana;
        _resumoMes = resumoMes;
        _carregando = false;
      });
    } catch (e, stack) {
      print('❌ Erro ao carregar gráficos: $e');
      print(stack);
      setState(() {
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return SizedBox(
        height: 260,
        child: Card(
          margin: const EdgeInsets.all(8),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: CarouselSlider(
        options: CarouselOptions(
          height: 240,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
          autoPlay: false,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Icon(Icons.info_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: resumo.totalGanhos,
                        color: Colors.green,
                        width: 24,
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: resumo.totalGastos,
                        color: Colors.red,
                        width: 24,
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (valor, meta) {
                        if (valor == 0) return const Text('Ganhos');
                        if (valor == 1) return const Text('Gastos');
                        return const Text('');
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ganhos: R\$${resumo.totalGanhos.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  'Gastos: R\$${resumo.totalGastos.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red),
                ),
                Text(
                  'Saldo: R\$${resumo.saldo.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: resumo.saldo >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
