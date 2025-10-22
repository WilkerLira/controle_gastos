class Transacao {
  final String tipo;
  final double valor;
  final DateTime data;
  final String tipoTransacao; // 'ganho' ou 'gasto'

  Transacao({
    required this.tipo,
    required this.valor,
    required this.data,
    required this.tipoTransacao,
  });
}
