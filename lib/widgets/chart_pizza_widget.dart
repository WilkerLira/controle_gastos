import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartPizzaWidget extends StatelessWidget {
  const ChartPizzaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Distribuição do Dia',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 250,
                      title: 'Ganhos',
                      color: Colors.green,
                      borderSide: BorderSide(),
                    ),
                    PieChartSectionData(
                      value: 150,
                      title: 'Gastos',
                      color: Colors.red,
                      borderSide: BorderSide(),
                    ),
                  ],
                ),
                duration: Duration(milliseconds: 300),
                curve: Curves.linear,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
