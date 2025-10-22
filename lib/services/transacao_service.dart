import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/transacao.dart';

class TransacaoService {
  static Future<List<Transacao>> carregarTransacoesPorPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    final List<Transacao> transacoes = [];

    // Carregar ganhos
    final ganhosSnapshot = await FirebaseFirestore.instance
        .collection('ganhos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .get();

    for (var doc in ganhosSnapshot.docs) {
      final data = doc.data();
      transacoes.add(
        Transacao(
          tipo: data['tipo'],
          valor: (data['valor'] as num).toDouble(),
          data: (data['data'] as Timestamp).toDate(),
          tipoTransacao: 'ganho',
        ),
      );
    }

    // Carregar gastos
    final gastosSnapshot = await FirebaseFirestore.instance
        .collection('gastos')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('data', isLessThan: Timestamp.fromDate(fim))
        .get();

    for (var doc in gastosSnapshot.docs) {
      final data = doc.data();
      transacoes.add(
        Transacao(
          tipo: data['tipo'],
          valor: (data['valor'] as num).toDouble(),
          data: (data['data'] as Timestamp).toDate(),
          tipoTransacao: 'gasto',
        ),
      );
    }

    return transacoes;
  }
}
