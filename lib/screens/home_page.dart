/*import 'package:controle_gastos/widgets/chart_pizza_widget.dart';
import 'package:controle_gastos/widgets/gasto_list_widget.dart';
import 'package:controle_gastos/widgets/graficos_carrossel_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/ganho_list_widget.dart'; // Certifique-se do caminho correto

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // fundo suave Material Design
      appBar: AppBar(
        title: const Text('Controle de Ganhos'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de ganhos
            const GanhoListWidget(),

            const SizedBox(height: 20),

            // Card de gastos (futuro)
            const GastoListWidget(),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              /* child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '💸 Card de gastos — (em breve)',
                  style: TextStyle(fontSize: 18),
                ),
              ),*/
            ),

            const SizedBox(height: 20),
            const ChartPizzaWidget(),
            // Card com gráficos (futuro)
            SizedBox(height: 280, child: const GraficosCarrosselWidget()),
          ],
        ),
      ),
    );
  }
}

Widget carouselCard() {
  return Scaffold(
    body: CarouselView(
      scrollDirection: Axis.horizontal,
      itemExtent: double.infinity,
      children: List<Widget>.generate(10, (int index) {
        return Center(child: ChartPizzaWidget());
      }),
    ),
  );
}*/

import 'package:controle_gastos/widgets/chart_pizza_widget.dart';
import 'package:controle_gastos/widgets/gasto_list_widget.dart';
import 'package:controle_gastos/widgets/graficos_carrossel_widget.dart';
import 'package:flutter/material.dart';
import '../widgets/ganho_list_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Controle de Ganhos'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              child: GraficosCarrosselWidget(), // sem "const"
            ),
            const GanhoListWidget(),
            const SizedBox(height: 20),
            const GastoListWidget(),
            const SizedBox(height: 20),
            const ChartPizzaWidget(),

            //const SizedBox(height: 20),
            // 👇 CORRIGIDO AQUI
          ],
        ),
      ),
    );
  }
}
