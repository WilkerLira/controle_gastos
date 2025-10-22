import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CardInput extends StatefulWidget {
  final void Function(Map<String, dynamic>) onSave;

  const CardInput({super.key, required this.onSave});

  @override
  State<CardInput> createState() => _CardInputState();
}

class _CardInputState extends State<CardInput> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();

  // tipo de ganho
  final Map<String, bool> _tipos = {'Uber': false, '99': false, 'Táxi': false};

  // gasto
  String _gastoSelecionado = 'Combustível';
  final List<String> _tiposGasto = ['Combustível', 'Alimentação', 'Outros'];

  void _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _salvar() {
    final tiposSelecionados = _tipos.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final dados = {
      'data': DateFormat('dd/MM/yyyy').format(_selectedDate),
      'tipos': tiposSelecionados,
      'valor': double.tryParse(_valorController.text) ?? 0.0,
      'gasto': _gastoSelecionado,
      'observacao': _obsController.text,
    };

    widget.onSave(dados);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DATA
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _selecionarData,
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // TIPO DE GANHO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _tipos.keys.map((tipo) {
                return Row(
                  children: [
                    Checkbox(
                      value: _tipos[tipo],
                      onChanged: (v) =>
                          setState(() => _tipos[tipo] = v ?? false),
                    ),
                    Text(tipo),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // VALOR
            TextField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor do ganho',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // GASTO
            DropdownButtonFormField<String>(
              value: _gastoSelecionado,
              items: _tiposGasto
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _gastoSelecionado = v!),
              decoration: const InputDecoration(
                labelText: 'Tipo de gasto',
                prefixIcon: Icon(Icons.local_gas_station),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // OBSERVAÇÃO
            TextField(
              controller: _obsController,
              decoration: const InputDecoration(
                labelText: 'Observação',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // BOTÃO SALVAR
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
