// lib/screens/home_screen.dart
import 'package:controle_gastos/widgets/circular_menu_button.dart';
import 'package:controle_gastos/widgets/gasto_list_widget.dart';
import 'package:controle_gastos/widgets/graficos_carrossel_widget.dart';
import 'package:controle_gastos/widgets/ganho_list_widget.dart';
import 'package:controle_gastos/widgets/graficos_linha_categoria.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✅ Chaves globais para acessar os estados dos widgets filhos
  final ganhoKey = GlobalKey<GanhoListWidgetState>();
  final gastoKey = GlobalKey<GastoListWidgetState>();
  final graficosKey = GlobalKey<GraficosCarrosselWidgetState>();

  /// Atualiza todos os widgets filhos com dados do dia atual
  Future<void> _atualizarTudo() async {
    final hoje = DateTime.now();
    try {
      // Executa as atualizações em paralelo para melhor desempenho
      await Future.wait([
        ganhoKey.currentState?.carregarGanhos(dataFiltro: hoje) ??
            Future.value(),
        gastoKey.currentState?.carregarGastos(dataFiltro: hoje) ??
            Future.value(),
        graficosKey.currentState?.carregarDados() ?? Future.value(),
      ]);
    } catch (e) {
      // Exibe erro ao usuário apenas se o contexto ainda estiver ativo
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      debugPrint('Erro ao atualizar dados: $e');
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Ganhos'),
        centerTitle: true,
        elevation: 2,
      ),
      floatingActionButton: const CircularMenuButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _atualizarTudo,
        color: Colors.green,
        backgroundColor: Colors.white,
        strokeWidth: 2.0,
        displacement: 40,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Garante que sempre seja possível puxar
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gráficos em carrossel
              SizedBox(
                height: 300,
                child: GraficosCarrosselWidget(key: graficosKey),
              ),
              const SizedBox(height: 20),

              // Gráfico de linha por categoria
              const GraficoLinhaCategoria(),
              const SizedBox(height: 20),

              // Lista de ganhos
              GanhoListWidget(key: ganhoKey),
              const SizedBox(height: 20),

              // Lista de gastos
              GastoListWidget(key: gastoKey),
              const SizedBox(
                height: 100,
              ), // ✅ Espaço extra para garantir scroll contínuo
            ],
          ),
        ),
      ),
    );
  }
}
