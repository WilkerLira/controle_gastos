import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GraficoLinhaCategoria extends StatefulWidget {
  const GraficoLinhaCategoria({super.key});

  @override
  State<GraficoLinhaCategoria> createState() => _GraficoLinhaCategoriaState();
}

class _GraficoLinhaCategoriaState extends State<GraficoLinhaCategoria> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!_pageController.hasClients) return;
      final next = (_pageController.page ?? 0).round() + 1;
      final pageCount = _categoriesKeys.length;
      if (pageCount == 0) return;
      final toPage = next >= pageCount ? 0 : next;
      _pageController.animateToPage(
        toPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  // Dados carregados do Firestore (formatado)
  Map<String, _CategoriaData> _categorias = {};
  List<String> get _categoriesKeys => _categorias.keys.toList();

  // Stream que busca ganhos e gastos e atualiza _categorias

  Future<void> _buildCategoriasFromSnapshots() async {
    // busca snapshots atuais (uma única leitura; você pode trocar por snapshots stream se quiser)
    final ganhosSnap = await FirebaseFirestore.instance
        .collection('ganhos')
        .get();
    final gastosSnap = await FirebaseFirestore.instance
        .collection('gastos')
        .get();

    // Map key: '<colecao>::<tipo>' -> _CategoriaData
    final Map<String, _CategoriaData> mapa = {};

    // Helper para processar docs
    void processDoc(QueryDocumentSnapshot doc, String origem) {
      final data = doc.data() as Map<String, dynamic>;
      final tipoRaw = (data['tipo'] ?? 'Outro').toString();
      final tipo = tipoRaw.trim();
      final valorNum = data['valor'];
      if (valorNum == null) return;
      final valor = (valorNum is num)
          ? valorNum.toDouble()
          : double.tryParse(valorNum.toString()) ?? 0.0;
      final ts = data['data'];
      DateTime dia;
      if (ts is Timestamp) {
        dia = ts.toDate();
      } else if (ts is DateTime) {
        dia = ts;
      } else {
        dia = DateTime.now();
      }

      final key =
          '$origem::$tipo'; // ex: 'ganhos::Uber' ou 'gastos::Combustível'
      mapa.putIfAbsent(key, () => _CategoriaData(tipo: tipo, origem: origem));
      mapa[key]!.adicionarRegistro(dia, valor);
    }

    for (var doc in ganhosSnap.docs) {
      processDoc(doc, 'ganhos');
    }
    for (var doc in gastosSnap.docs) {
      processDoc(doc, 'gastos');
    }

    // Atualiza estado
    setState(() {
      _categorias = mapa;
    });
  }

  // Para atualização em tempo real, vamos ouvir snapshots e rebuildar
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subGanhos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subGastos;

  void _subscribeRealtime() {
    _subGanhos?.cancel();
    _subGastos?.cancel();

    _subGanhos = FirebaseFirestore.instance
        .collection('ganhos')
        .snapshots()
        .listen((_) {
          _buildCategoriasFromSnapshots();
        });

    _subGastos = FirebaseFirestore.instance
        .collection('gastos')
        .snapshots()
        .listen((_) {
          _buildCategoriasFromSnapshots();
        });

    // primeira carga
    _buildCategoriasFromSnapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Inicializa o subscribe no primeiro build
    if (_subGanhos == null || _subGastos == null) {
      _subscribeRealtime();
    }

    if (_categorias.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('Nenhum dado para exibir.')),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _categoriesKeys.length,
        itemBuilder: (context, index) {
          final key = _categoriesKeys[index];
          final cat = _categorias[key]!;

          // calcula spots por dia do mês atual (garante ordem)
          final now = DateTime.now();
          final ultimoDia = DateTime(now.year, now.month + 1, 0).day;
          final List<FlSpot> spots = [];
          final List<DateTime> dias = [];

          // Preenche lista de dias do mês atual
          for (int d = 1; d <= ultimoDia; d++) {
            final day = DateTime(now.year, now.month, d);
            dias.add(day);
            final soma = cat.somaNoDia(day);
            spots.add(FlSpot((d - 1).toDouble(), soma));
          }

          // calcula maxY para escala (usa valores absolutos)
          double maxAbs = 0;
          for (var s in spots) {
            final v = s.y.abs();
            if (v > maxAbs) maxAbs = v;
          }
          if (maxAbs <= 0) maxAbs = 1;
          final maxY = maxAbs * 1.2;

          final isGanho = cat.origem == 'ganhos';
          final linhaColor = isGanho
              ? Colors.green.shade600
              : Colors.red.shade600;
          final areaColor = linhaColor.withAlpha(18);
          final dotColorPos = isGanho
              ? Colors.green.shade700
              : Colors.red.shade700;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // título com tipo e total do mês
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${cat.tipo} • ${isGanho ? 'Ganho' : 'Gasto'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'R\$ ${cat.totalNoMes().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isGanho
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // gráfico (usa Expanded para preencher)
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: -maxY,
                        maxY: maxY,
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            //tooltipBgColor: Colors.black87,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((t) {
                                final dayIndex = t.x.toInt();
                                final day = dias[dayIndex];
                                final value = t.y;
                                final formatted =
                                    NumberFormat.currency(
                                      locale: 'pt_BR',
                                      symbol: 'R\$',
                                    ).format(
                                      isGanho ? value : value,
                                    ); // mostramos valor direto
                                final sign = isGanho ? '' : '-';
                                return LineTooltipItem(
                                  '${DateFormat('dd/MM').format(day)}\n$sign$formatted',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: Colors.grey.withAlpha(12),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: maxY / 3, // Menos linhas
                              reservedSize: 70, // Mais espaço
                              getTitlesWidget: (value, meta) {
                                if (value < 0) {
                                  return const SizedBox.shrink();
                                }
                                // Formatação compacta
                                String formatarValor(double valor) {
                                  if (valor >= 10000)
                                    return '${(valor / 1000).toStringAsFixed(0)}k';
                                  if (valor >= 1000)
                                    return '${(valor / 1000).toStringAsFixed(1)}k';
                                  return valor.toInt().toString();
                                }

                                return Text(
                                  formatarValor(value),
                                  style: const TextStyle(
                                    fontSize: 10,
                                  ), // Fonte menor
                                );
                              },
                            ),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 5, // espaça os rótulos
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i >= 0 && i < dias.length) {
                                  return Transform.rotate(
                                    angle: -0.5, // inclina para não sobrepor
                                    child: Text(
                                      '${dias[i].day}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 22, // garante espaço para o texto
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: linhaColor,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                // ponto vazio quando valor == 0
                                if (spot.y == 0) {
                                  return FlDotCirclePainter(
                                    radius: 2,
                                    color: Colors.grey.withAlpha(40),
                                  );
                                }
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: dotColorPos,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: areaColor,
                            ),
                          ),
                        ],
                      ),
                      // swapAnimationDuration: const Duration(milliseconds: 600),
                      // swapAnimationCurve: Curves.easeOut,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // legenda compacta (ícone + valor total do mês)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isGanho ? Icons.trending_up : Icons.trending_down,
                            color: linhaColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat.yMMMM().format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${cat.qtdDiasComMovimento()} dias',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Classe auxiliar que guarda registros de uma categoria e faz somas por dia
class _CategoriaData {
  final String tipo;
  final String origem; // 'ganhos' ou 'gastos'
  final List<_Registro> _registros = [];

  _CategoriaData({required this.tipo, required this.origem});

  void adicionarRegistro(DateTime data, double valor) {
    // normaliza para dia (00:00)
    final dia = DateTime(data.year, data.month, data.day);
    _registros.add(_Registro(dia: dia, valor: valor));
  }

  // soma por dia (retorna soma dos valores daquele dia; para gastos mantemos positivo para visual)
  double somaNoDia(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    double s = 0;
    for (var r in _registros) {
      if (r.dia == d) s += (origem == 'gastos' ? r.valor : r.valor);
    }
    return s;
  }

  // total no mês atual
  double totalNoMes() {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1);
    final fim = DateTime(now.year, now.month + 1, 1);
    double s = 0;
    for (var r in _registros) {
      if (r.dia.isAfter(inicio.subtract(const Duration(days: 1))) &&
          r.dia.isBefore(fim)) {
        s += (origem == 'gastos' ? r.valor : r.valor);
      }
    }
    return s;
  }

  int qtdDiasComMovimento() {
    final now = DateTime.now();
    final inicio = DateTime(now.year, now.month, 1);
    final fim = DateTime(now.year, now.month + 1, 1);
    final dias = <DateTime>{};
    for (var r in _registros) {
      if (r.dia.isAfter(inicio.subtract(const Duration(days: 1))) &&
          r.dia.isBefore(fim)) {
        dias.add(r.dia);
      }
    }
    return dias.length;
  }
}

class _Registro {
  final DateTime dia;
  final double valor;
  _Registro({required this.dia, required this.valor});
}
