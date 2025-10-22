import 'package:flutter/material.dart';

class ResumoPeriodoCard extends StatelessWidget {
  final String periodo;
  final double ganhos;
  final double gastos;

  const ResumoPeriodoCard({
    super.key,
    required this.periodo,
    required this.ganhos,
    required this.gastos,
  });

  @override
  Widget build(BuildContext context) {
    final lucro = ganhos - gastos;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              periodo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem(Icons.arrow_upward, 'Ganhos', ganhos, Colors.green),
                _infoItem(Icons.arrow_downward, 'Gastos', gastos, Colors.red),
                _infoItem(Icons.monetization_on, 'Lucro', lucro, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _infoItem(IconData icon, String label, double valor, Color color) {
  return Column(
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      Text(
        'R\$ ${valor.toStringAsFixed(2)}',
        style: TextStyle(color: color, fontSize: 16),
      ),
    ],
  );
}
