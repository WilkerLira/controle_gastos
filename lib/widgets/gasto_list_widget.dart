import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GastoListWidget extends StatefulWidget {
  const GastoListWidget({super.key});

  @override
  State<GastoListWidget> createState() => GastoListWidgetState();
}

class GastoListWidgetState extends State<GastoListWidget> {
  final TextEditingController valorController = TextEditingController();
  final TextEditingController dataController = TextEditingController();
  DateTime? dataSelecionada;
  String? tipoSelecionado;
  final List<Map<String, dynamic>> gastos = [];

  final List<String> tiposGasto = [
    'Combustível',
    'Alimentação',
    'Aluguel Carro',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    dataSelecionada = DateTime.now();
    dataController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada!);
    carregarGastos(dataFiltro: dataSelecionada); // <-- Carrega dados ao abrir
  }

  double get totalGastos {
    return gastos.fold(0.0, (soma, item) => soma + (item['valor'] as double));
  }

  Future<void> carregarGastos({DateTime? dataFiltro}) async {
    final data = dataFiltro ?? dataSelecionada ?? DateTime.now();

    // Define o intervalo do dia selecionado
    final inicioDoDia = DateTime(data.year, data.month, data.day);
    final fimDoDia = inicioDoDia.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('gastos')
        .where('data', isGreaterThanOrEqualTo: inicioDoDia)
        .where('data', isLessThan: fimDoDia)
        .orderBy('data', descending: true)
        .get();

    final lista = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'tipo': data['tipo'],
        'valor': (data['valor'] as num).toDouble(),
        'data': (data['data'] as Timestamp).toDate(),
      };
    }).toList();

    setState(() {
      gastos
        ..clear()
        ..addAll(lista);
    });
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
      await carregarGastos(dataFiltro: novaData);
    }
  }

  Future<void> adicionarGasto() async {
    final valorTexto = valorController.text.trim();
    if (tipoSelecionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Escolha o tipo de gasto')));
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

    final gasto = {
      'tipo': tipoSelecionado,
      'valor': valor,
      'data': dataSelecionada ?? DateTime.now(),
      'criadoEm': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('gastos').add(gasto);

      setState(() {
        gastos.add(gasto);
        valorController.clear();
        tipoSelecionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto adicionado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar gasto!')));
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
              'Gastos do Dia',
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
                    items: tiposGasto
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
                  onPressed: adicionarGasto,
                  icon: const Icon(Icons.remove),
                  label: const Text('Adicionar'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (gastos.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: gastos.length,
                  itemBuilder: (context, index) {
                    final g = gastos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(g['tipo']),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(g['data']),
                        ),
                        trailing: Text(
                          '- R\$ ${(g['valor'] as double).toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              const Text(
                'Nenhum gasto registrado ainda.',
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: R\$ ${totalGastos.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
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
