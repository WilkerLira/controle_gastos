import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResumoFinanceiroPage extends StatefulWidget {
  const ResumoFinanceiroPage({super.key});

  @override
  State<ResumoFinanceiroPage> createState() => _ResumoFinanceiroPageState();
}

class _ResumoFinanceiroPageState extends State<ResumoFinanceiroPage> {
  DateTime mesAtual = DateTime.now();
  double totalGanhos = 0.0;
  double totalGastos = 0.0;
  double saldo = 0.0;
  bool carregando = true;

  Map<String, List<double>> resumoSemanal = {
    'ganhos': [0, 0, 0, 0],
    'gastos': [0, 0, 0, 0],
  };

  Map<String, double> gastosPorTipo = {};
  Map<String, double> totaisPorTipo = {};

  final NumberFormat formatoMoeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    carregarResumo();
  }

  void mudarMes(int delta) {
    setState(() {
      mesAtual = DateTime(mesAtual.year, mesAtual.month + delta, 1);
    });
    carregarResumo();
  }

  Future<void> carregarResumo() async {
    setState(() => carregando = true);

    final firestore = FirebaseFirestore.instance;
    final inicioMes = DateTime(mesAtual.year, mesAtual.month, 1);
    final fimMes = DateTime(mesAtual.year, mesAtual.month + 1, 0);

    try {
      double ganhos = 0.0;
      double gastos = 0.0;
      final Map<String, double> mapaGastos = {};
      final List<double> ganhosSemanal = List.filled(4, 0.0);
      final List<double> gastosSemanal = List.filled(4, 0.0);

      // ----------------- Ganhos -----------------
      final ganhosSnap = await firestore
          .collection('ganhos')
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(fimMes))
          .get();

      for (var doc in ganhosSnap.docs) {
        final dados = doc.data();
        final ts = dados['data'];
        DateTime data;
        if (ts is Timestamp) {
          data = ts.toDate();
        } else if (ts is DateTime) {
          data = ts;
        } else {
          data = DateTime.now();
        }

        final valor = (dados['valor'] as num?)?.toDouble() ?? 0.0;
        ganhos += valor;

        final semana = ((data.day - 1) ~/ 7);
        if (semana < ganhosSemanal.length) ganhosSemanal[semana] += valor;
      }

      // ----------------- Gastos -----------------
      final gastosSnap = await firestore
          .collection('gastos')
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(fimMes))
          .get();

      for (var doc in gastosSnap.docs) {
        final dados = doc.data();
        final ts = dados['data'];
        DateTime data;
        if (ts is Timestamp) {
          data = ts.toDate();
        } else if (ts is DateTime) {
          data = ts;
        } else {
          data = DateTime.now();
        }

        final valor = (dados['valor'] as num?)?.toDouble() ?? 0.0;
        final tipoBruto = (dados['tipo'] as String?) ?? 'Outros';

        gastos += valor;
        mapaGastos[tipoBruto] = (mapaGastos[tipoBruto] ?? 0.0) + valor;

        final semana = ((data.day - 1) ~/ 7);
        if (semana < gastosSemanal.length) gastosSemanal[semana] += valor;
      }

      // totaisPorTipo agora contém APENAS gastos por tipo (coerente com o gráfico de pizza)
      final ordenado = Map.fromEntries(
        mapaGastos.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );

      setState(() {
        totalGanhos = ganhos;
        totalGastos = gastos;
        saldo = ganhos - gastos;
        gastosPorTipo = mapaGastos;
        resumoSemanal = {'ganhos': ganhosSemanal, 'gastos': gastosSemanal};
        totaisPorTipo = ordenado;
        carregando = false;
      });
    } catch (e, st) {
      debugPrint('Erro ao carregar resumo: $e\n$st');
      setState(() => carregando = false);
    }
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = gastosPorTipo.values.fold(0.0, (a, b) => a + b);

    if (gastosPorTipo.isEmpty || total <= 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade400,
          value: 1,
          title: 'Sem dados',
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }

    return gastosPorTipo.entries.map((e) {
      final percentual = (e.value / total) * 100;
      final cor = _colorForCategory(e.key);

      return PieChartSectionData(
        color: cor,
        value: e.value,
        title: percentual >= 4 ? '${percentual.toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Color _colorForCategory(String tipo) {
    final Map<String, Color> coresFixas = {
      'Alimentação': const Color(0xFFE67E22),
      'Combustível': const Color(0xFF3498DB),
      'Aluguel': const Color(0xFF8E44AD),
      'Uber': const Color(0xFFE91E63),
      'Transporte': const Color(0xFF00BCD4),
      'Saúde': const Color(0xFFE74C3C),
      'Educação': const Color(0xFF1ABC9C),
      'Lazer': const Color(0xFF8E44AD),
      'Outros': Colors.grey.shade600,
    };

    if (coresFixas.containsKey(tipo)) {
      return coresFixas[tipo]!;
    }

    final List<Color> coresExtras = [
      Colors.brown,
      Colors.indigo,
      Colors.green.shade700,
      Colors.deepOrange,
      Colors.lime.shade700,
      Colors.amber.shade700,
      Colors.redAccent,
      Colors.blueAccent,
    ];

    int hash = tipo.hashCode;
    if (hash.isNegative) hash = -hash;
    final int index = hash % coresExtras.length;
    return coresExtras[index];
  }

  Widget _buildLegenda(Color cor, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: cor,
          margin: const EdgeInsets.only(right: 4),
        ),
        Text(texto, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildResumoTotaisPorTipo() {
    if (totaisPorTipo.isEmpty) {
      return const Text('Nenhum gasto encontrado no período.');
    }

    final nomeMes = DateFormat('MMMM yyyy', 'pt_BR').format(mesAtual);

    final lista = totaisPorTipo.entries.map((e) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: _colorForCategory(e.key),
                ),
                const SizedBox(width: 8),
                Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Text(
              formatoMoeda.format(e.value),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gastos por tipo ($nomeMes)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...lista,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeMes = DateFormat.MMMM('pt_BR').format(mesAtual);
    final ano = mesAtual.year;

    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    // Evita maxY = 0
    final maxYValue = (totalGanhos > totalGastos ? totalGanhos : totalGastos);
    final maxY = maxYValue > 0 ? maxYValue * 1.2 : 100.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resumo Financeiro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF272757),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF272757),
        onRefresh: carregarResumo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do mês e navegação
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => mudarMes(-1),
                  ),
                  Text(
                    '${nomeMes[0].toUpperCase()}${nomeMes.substring(1)} $ano',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => mudarMes(1),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cards coloridos
              Row(
                children: [
                  _buildResumoCard('Saldo', saldo, const Color(0xFF272757)),
                  const SizedBox(width: 8),
                  _buildResumoCard(
                    'Ganhos',
                    totalGanhos,
                    const Color(0xFF2ECC71),
                  ),
                  const SizedBox(width: 8),
                  _buildResumoCard(
                    'Gastos',
                    totalGastos,
                    const Color(0xFFE74C3C),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              const Text(
                'Resumo Semanal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: maxY,
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, _) => Text(
                            'R\$${value.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final semanas = ['S1', 'S2', 'S3', 'S4'];
                            final idx = value.toInt();
                            if (idx >= 0 && idx < semanas.length) {
                              return Text(semanas[idx]);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    barGroups: List.generate(
                      resumoSemanal['ganhos']!.length,
                      (i) => _makeGroupData(
                        i,
                        resumoSemanal['ganhos']![i],
                        resumoSemanal['gastos']![i],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegenda(Colors.green, 'Ganhos'),
                  const SizedBox(width: 16),
                  _buildLegenda(Colors.red, 'Gastos'),
                ],
              ),

              const SizedBox(height: 28),
              const Text(
                'Distribuição por Tipo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(),
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: gastosPorTipo.keys.map((tipo) {
                  final color = _colorForCategory(tipo);
                  return _buildLegenda(color, tipo);
                }).toList(),
              ),

              const SizedBox(height: 28),
              _buildResumoTotaisPorTipo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumoCard(String titulo, double valor, Color cor) {
    return Expanded(
      child: Card(
        color: cor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatoMoeda.format(valor),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double ganho, double gasto) {
    return BarChartGroupData(
      x: x,
      barsSpace: 6,
      barRods: [
        BarChartRodData(toY: ganho, color: Colors.green, width: 10),
        BarChartRodData(toY: gasto, color: Colors.red, width: 10),
      ],
    );
  }
}
