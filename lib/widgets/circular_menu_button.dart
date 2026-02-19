import 'dart:math' as math;
import 'package:controle_gastos/screens/despesas_fixas_page.dart';
import 'package:controle_gastos/widgets/financial_summary_widget.dart';
import 'package:flutter/material.dart';
import 'package:controle_gastos/models/financial_summary_model.dart';

class CircularMenuButton extends StatefulWidget {
  const CircularMenuButton({super.key});

  @override
  State<CircularMenuButton> createState() => _CircularMenuButtonState();
}

class _CircularMenuButtonState extends State<CircularMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _aberto = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_aberto) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _aberto = !_aberto);
  }

  void _abrirResumo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResumoFinanceiroPage()),
    );
  }

  void _abrirDespesasFixas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DespesasFixasPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itens = [
      _MenuItem(
        icon: Icons.home_work,
        color: Color(0xFF8E44AD),
        onTap: (_abrirDespesasFixas),
      ),
      _MenuItem(icon: Icons.money_off, color: Color(0xFFC0392B), onTap: () {}),
      _MenuItem(
        icon: Icons.analytics,
        color: Color(0xFF2980B9),
        onTap: _abrirResumo,
      ),
    ];

    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_aberto)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(color: Colors.white.withAlpha(30)),
            ),

          ...List.generate(itens.length, (i) {
            final angulo =
                (i * 45) * (math.pi / 180); // espaçamento entre botões
            return AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                final offset = Offset.fromDirection(
                  angulo,
                  _controller.value * 100,
                );
                return Positioned(
                  right: 20 + offset.dx,
                  bottom: 20 + offset.dy,
                  child: Opacity(
                    opacity: _controller.value,
                    child: Transform.scale(
                      scale: _controller.value,
                      child: FloatingActionButton(
                        heroTag: null,
                        backgroundColor: itens[i].color,
                        onPressed: itens[i].onTap,
                        child: Icon(itens[i].icon, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          Padding(
            padding: const EdgeInsets.all(30),
            child: FloatingActionButton(
              backgroundColor: Color(0xFF272757),
              onPressed: _toggleMenu,
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                color: Colors.white,
                progress: _controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.color, required this.onTap});
}
