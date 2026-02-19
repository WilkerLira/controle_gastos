// =============================================================
//  DESPESAS FIXAS — COMPLETO, COM CONTROLE DE MÊS (SEM QUEBRAR UI)
// =============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// -------------------------------------------------------------
// CORES POR CATEGORIA
// -------------------------------------------------------------
Color _colorForCategory(String categoria) {
  final Map<String, Color> cores = {
    'Moradia': const Color(0xFF8E44AD),
    'Utilidades': const Color(0xFF3498DB),
    'Comunicação': const Color(0xFF2980B9),
    'Assinaturas': const Color(0xFF1ABC9C),
    'Dívidas': const Color(0xFFE74C3C),
    'Impostos': const Color(0xFFE67E22),
    'Obrigações Legais': const Color(0xFFC0392B),
    'Outros': Colors.grey,
  };
  return cores[categoria] ?? Colors.grey;
}

// =============================================================
// PAGE
// =============================================================
class DespesasFixasPage extends StatefulWidget {
  const DespesasFixasPage({super.key});

  @override
  State<DespesasFixasPage> createState() => _DespesasFixasPageState();
}

class _DespesasFixasPageState extends State<DespesasFixasPage>
    with SingleTickerProviderStateMixin {
  final NumberFormat _moeda = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
  );

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _mesSelecionado = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  List<Map<String, dynamic>> _despesas = [];
  double _totalMensal = 0.0;

  late AnimationController _animController;

  // -------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _carregarDespesas();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------
  // CARREGAR DESPESAS POR MÊS
  // -------------------------------------------------------------
  Future<void> _carregarDespesas() async {
    try {
      final inicioMesSelecionado = DateTime(
        _mesSelecionado.year,
        _mesSelecionado.month,
        1,
      );

      final snapshot = await _firestore
          .collection('despesas_fixas')
          .get(); // 🔥 NÃO filtra por mês/ano no firebase

      final lista = snapshot.docs
          .map((doc) {
            final data = doc.data();

            final Timestamp? inicioTs = data['inicio'];
            final DateTime inicio = inicioTs?.toDate() ?? DateTime(2000, 1, 1);

            // 🔥 regra correta:
            // só mostra se a despesa já existia no mês selecionado
            if (inicio.isAfter(inicioMesSelecionado)) return null;

            return {
              'id': doc.id,
              'descricao': data['descricao'] ?? 'Sem título',
              'valor': (data['valor'] as num?)?.toDouble() ?? 0.0,
              'categoria': data['categoria'] ?? 'Outros',
              'diaVencimento': data['diaVencimento'] ?? 1,
              'observacoes': data['observacoes'] ?? '',
              'ativa': data['ativa'] ?? true,
              'inicio': inicio,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      final total = lista
          .where((d) => d['ativa'] == true)
          .fold(0.0, (acc, x) => acc + (x['valor'] as double));

      setState(() {
        _despesas = lista;
        _totalMensal = total;
      });

      _animController.forward(from: 0);
    } catch (e) {
      debugPrint('Erro ao carregar despesas fixas: $e');
    }
  }

  // -------------------------------------------------------------
  // SELETOR DE MÊS
  // -------------------------------------------------------------
  Widget _buildMonthSelector() {
    final formatter = DateFormat('MMMM yyyy', 'pt_BR');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _mesSelecionado = DateTime(
                _mesSelecionado.year,
                _mesSelecionado.month - 1,
                1,
              );
            });
            _carregarDespesas();
          },
        ),
        Text(
          formatter.format(_mesSelecionado).toUpperCase(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _mesSelecionado = DateTime(
                _mesSelecionado.year,
                _mesSelecionado.month + 1,
                1,
              );
            });
            _carregarDespesas();
          },
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GRÁFICO POR CATEGORIA
  // -------------------------------------------------------------
  Widget _buildGraficoCategorias() {
    if (_despesas.isEmpty) return const SizedBox();

    final Map<String, double> somaCategorias = {};

    for (var d in _despesas.where((x) => x['ativa'] == true)) {
      somaCategorias[d['categoria']] =
          (somaCategorias[d['categoria']] ?? 0) + d['valor'];
    }

    final maior = somaCategorias.values.isEmpty
        ? 1
        : somaCategorias.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Distribuição por categoria",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...somaCategorias.entries.map((e) {
              final cor = _colorForCategory(e.key);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      final largura =
                          (e.value / maior) * _animController.value * 240;
                      return Container(
                        height: 14,
                        width: largura.clamp(10.0, 240),
                        decoration: BoxDecoration(
                          color: cor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _moeda.format(e.value),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Despesas Fixas"),
        centerTitle: true,
        backgroundColor: const Color(0xFF272757),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DespesaFixaForm()),
          ).then((_) => _carregarDespesas());
        },
        backgroundColor: const Color(0xFF272757),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarDespesas,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _despesas.isEmpty
              ? const Center(child: Text("Nenhuma despesa fixa cadastrada"))
              : Column(
                  children: [
                    _buildMonthSelector(),
                    const SizedBox(height: 12),
                    _buildResumo(),
                    const SizedBox(height: 16),
                    _buildGraficoCategorias(),
                    const SizedBox(height: 16),
                    ..._despesas.map(_buildItem).toList(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResumo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total mensal",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _moeda.format(_totalMensal),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> d) {
    final cor = _colorForCategory(d['categoria']);
    final ativa = d['ativa'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () async {
          // EDITAR
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DespesaFixaForm(docId: d['id'], data: d),
            ),
          );
          _carregarDespesas();
        },

        onLongPress: () async {
          // EXCLUIR
          final confirm = await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Excluir despesa"),
              content: const Text("Deseja realmente excluir?"),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: const Text("Excluir"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _firestore.collection('despesas_fixas').doc(d['id']).delete();

            _carregarDespesas();
          }
        },

        leading: Icon(Icons.circle, color: ativa ? cor : Colors.grey, size: 12),

        title: Text(
          d['descricao'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ativa ? Colors.black : Colors.grey,
          ),
        ),

        subtitle: Text(
          "R\$ ${d['valor'].toStringAsFixed(2)} • Dia ${d['diaVencimento']}",
        ),

        trailing: Switch(
          value: ativa,
          onChanged: (v) async {
            await _firestore.collection('despesas_fixas').doc(d['id']).update({
              'ativa': v,
            });

            _carregarDespesas();
          },
        ),
      ),
    );
  }
}

// =============================================================
// FORMULÁRIO
// =============================================================
class DespesaFixaForm extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? data;

  const DespesaFixaForm({super.key, this.docId, this.data});

  @override
  State<DespesaFixaForm> createState() => _DespesaFixaFormState();
}

class _DespesaFixaFormState extends State<DespesaFixaForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  final _dia = TextEditingController(text: '1');
  final _obs = TextEditingController();

  String _categoria = 'Outros';
  bool _ativa = true;

  final List<String> _categorias = [
    'Moradia',
    'Utilidades',
    'Comunicação',
    'Assinaturas',
    'Dívidas',
    'Impostos',
    'Obrigações Legais',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.data != null) {
      _descricao.text = widget.data!['descricao'] ?? '';
      _valor.text = (widget.data!['valor'] ?? '').toString();
      _dia.text = (widget.data!['diaVencimento'] ?? 1).toString();
      _obs.text = widget.data!['observacoes'] ?? '';
      _categoria = widget.data!['categoria'] ?? 'Outros';
      _ativa = widget.data!['ativa'] ?? true;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    double valorConvertido = 0.0;

    String texto = _valor.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    if (texto.isNotEmpty) {
      valorConvertido = double.tryParse(texto) ?? 0.0;
    }

    final dados = {
      'descricao': _descricao.text.trim(),
      'categoria': _categoria,
      'valor': valorConvertido,
      'diaVencimento': int.parse(_dia.text),
      'observacoes': _obs.text.trim(),
      'ativa': _ativa,
      'mes': now.month,
      'ano': now.year,
      'inicio': DateTime(now.year, now.month, 1),
    };

    if (widget.docId == null) {
      await _firestore.collection('despesas_fixas').add(dados);
    } else {
      await _firestore
          .collection('despesas_fixas')
          .doc(widget.docId)
          .update(dados);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Despesa Fixa"),
        backgroundColor: const Color(0xFF272757),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descricao,
                decoration: const InputDecoration(labelText: "Descrição"),
                validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  _CurrencyInputFormatter(),
                ],
                decoration: const InputDecoration(labelText: "Valor"),
                validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField(
                value: _categoria,
                items: _categorias
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
                decoration: const InputDecoration(labelText: "Categoria"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dia,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Dia do vencimento",
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text("Despesa ativa"),
                value: _ativa,
                onChanged: (v) => setState(() => _ativa = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _salvar, child: const Text("Salvar")),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    double value = double.parse(digits) / 100;

    final formatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: '',
      decimalDigits: 2,
    ).format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
