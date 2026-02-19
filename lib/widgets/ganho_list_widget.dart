import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GanhoListWidget extends StatefulWidget {
  const GanhoListWidget({super.key});

  @override
  State<GanhoListWidget> createState() => GanhoListWidgetState();
}

class GanhoListWidgetState extends State<GanhoListWidget> {
  final TextEditingController valorController = TextEditingController();
  final TextEditingController dataController = TextEditingController();
  DateTime? dataSelecionada;
  String? tipoSelecionado;
  final List<Map<String, dynamic>> ganhos = [];

  final List<String> tiposGanho = ['Uber', '99', 'Táxi'];

  double get totalGanhos {
    return ganhos.fold(0.0, (soma, item) {
      final v = item['valor'];
      if (v is num) return soma + v.toDouble();
      return soma;
    });
  }

  @override
  void initState() {
    super.initState();
    dataSelecionada = DateTime.now();
    dataController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada!);
    carregarGanhos(dataFiltro: dataSelecionada);
  }

  @override
  void dispose() {
    valorController.dispose();
    dataController.dispose();
    super.dispose();
  }

  Future<void> selecionarData() async {
    final DateTime? novaData = await showDatePicker(
      context: context,
      initialDate: dataSelecionada ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (novaData != null) {
      setState(() {
        dataSelecionada = novaData;
        dataController.text = DateFormat('dd/MM/yyyy').format(novaData);
      });
      await carregarGanhos(dataFiltro: novaData);
    }
  }

  Future<void> carregarGanhos({DateTime? dataFiltro}) async {
    final data = dataFiltro ?? dataSelecionada ?? DateTime.now();

    final inicioDoDia = DateTime(data.year, data.month, data.day);
    final fimDoDia = inicioDoDia.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('ganhos')
        .where('data', isGreaterThanOrEqualTo: inicioDoDia)
        .where('data', isLessThan: fimDoDia)
        .orderBy('data', descending: true)
        .get();

    final lista = snapshot.docs.map((doc) {
      final d = doc.data();
      return {
        'tipo': d['tipo'],
        'valor': (d['valor'] as num).toDouble(),
        'data': (d['data'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() {
      ganhos
        ..clear()
        ..addAll(lista);
    });
  }

  Future<void> adicionarGanho() async {
    final valorTexto = valorController.text.trim();
    if (tipoSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Escolha o tipo de ganho')));
      return;
    }
    if (valorTexto.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe o valor')));
      return;
    }

    final valorLimpo = valorTexto.replaceAll('.', '').replaceAll(',', '.');
    final valor = double.tryParse(valorLimpo);

    if (valor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Valor inválido')));
      return;
    }

    // 🔥 Converte a data para Timestamp antes de salvar
    final novoGanho = {
      'tipo': tipoSelecionado!,
      'valor': valor,
      'data': Timestamp.fromDate(dataSelecionada ?? DateTime.now()),
    };

    try {
      final ref = await FirebaseFirestore.instance
          .collection('ganhos')
          .add(novoGanho);
      final doc = await ref.get();

      final dados = doc.data();
      if (dados != null) {
        final ganhoConvertido = {
          'tipo': dados['tipo'],
          'valor': (dados['valor'] as num).toDouble(),
          'data': (dados['data'] as Timestamp).toDate(),
        };

        setState(() {
          ganhos.add(ganhoConvertido);
          valorController.clear();
          tipoSelecionado = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ganho adicionado com sucesso')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ganhos do Dia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String>(
                    initialValue: tipoSelecionado,
                    hint: const Text('Tipo'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: tiposGanho
                        .map(
                          (tipo) =>
                              DropdownMenuItem(value: tipo, child: Text(tipo)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => tipoSelecionado = v),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: valorController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Valor (R\$)',
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: dataController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Data',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: selecionarData,
                      ),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: adicionarGanho,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (ganhos.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ganhos.length,
                  itemBuilder: (context, index) {
                    final g = ganhos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(g['tipo']),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(g['data']),
                        ),
                        trailing: Text(
                          'R\$ ${(g['valor'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Text(
                'Nenhum ganho registrado ainda.',
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: R\$ ${totalGanhos.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    double value = double.parse(clean) / 100;
    String newText = _formatter.format(value);
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
