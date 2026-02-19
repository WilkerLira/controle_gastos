import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FinancialSummaryModel extends ChangeNotifier {
  DateTime currentMonth = DateTime.now();
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double balance = 0.0;
  bool isLoading = true;

  Map<String, List<double>> weeklySummary = {
    'income': [0, 0, 0, 0],
    'expenses': [0, 0, 0, 0],
  };

  Map<String, double> expensesByType = {};
  Map<String, double> totalsByType = {};

  void changeMonth(int delta) {
    currentMonth = DateTime(currentMonth.year, currentMonth.month + delta, 1);
    loadSummary();
  }

  Future<void> loadSummary() async {
    isLoading = true;
    notifyListeners();

    await _gerarDespesasFixasDoMes();

    final firestore = FirebaseFirestore.instance;
    final startOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final endOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    try {
      debugPrint(
        'Carregando resumo para ${currentMonth.month}/${currentMonth.year}',
      );
      double income = 0.0;
      double expenses = 0.0;
      final Map<String, double> expenseMap = {};
      final List<double> weeklyIncome = List.filled(4, 0.0);
      final List<double> weeklyExpenses = List.filled(4, 0.0);

      // Load income
      final incomeSnapshot = await firestore
          .collection('ganhos')
          .where(
            'data',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      debugPrint(
        'Encontrados ${incomeSnapshot.docs.length} documentos de ganhos',
      );
      for (var doc in incomeSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['data'];
        DateTime date;
        if (timestamp is Timestamp) {
          date = timestamp.toDate();
        } else if (timestamp is DateTime) {
          date = timestamp;
        } else {
          date = DateTime.now();
        }

        final value = (data['valor'] as num?)?.toDouble() ?? 0.0;
        income += value;

        final week = ((date.day - 1) ~/ 7);
        if (week < weeklyIncome.length) weeklyIncome[week] += value;
      }

      // Load expenses
      final expensesSnapshot = await firestore
          .collection('gastos')
          .where(
            'data',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      debugPrint(
        'Encontrados ${expensesSnapshot.docs.length} documentos de gastos',
      );
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final timestamp = data['data'];
        DateTime date;
        if (timestamp is Timestamp) {
          date = timestamp.toDate();
        } else if (timestamp is DateTime) {
          date = timestamp;
        } else {
          date = DateTime.now();
        }

        final value = (data['valor'] as num?)?.toDouble() ?? 0.0;
        final type = (data['tipo'] as String?) ?? 'Outros';

        expenses += value;
        expenseMap[type] = (expenseMap[type] ?? 0.0) + value;

        final week = ((date.day - 1) ~/ 7);
        if (week < weeklyExpenses.length) weeklyExpenses[week] += value;
      }

      final sorted = Map.fromEntries(
        expenseMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );

      totalIncome = income;
      totalExpenses = expenses;
      balance = income - expenses;
      expensesByType = expenseMap;
      weeklySummary = {'income': weeklyIncome, 'expenses': weeklyExpenses};
      totalsByType = sorted;
      isLoading = false;
      debugPrint(
        'Resumo carregado: Ganhos: $income, Gastos: $expenses, Saldo: $balance',
      );
      notifyListeners();
    } catch (e, st) {
      debugPrint('Erro ao carregar resumo: $e\n$st');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _gerarDespesasFixasDoMes() async {
    final firestore = FirebaseFirestore.instance;

    final inicioMes = DateTime(currentMonth.year, currentMonth.month, 1);
    final fimMes = DateTime(currentMonth.year, currentMonth.month + 1, 0);

    final fixasSnapshot = await firestore
        .collection('despesas_fixas')
        .where('ativa', isEqualTo: true)
        .get();

    for (var fixa in fixasSnapshot.docs) {
      final data = fixa.data();

      final dia = (data['diaVencimento'] ?? 1).clamp(1, fimMes.day);
      final dataLancamento = DateTime(
        currentMonth.year,
        currentMonth.month,
        dia,
      );

      // Verifica se já existe gasto fixo no mês
      final existente = await firestore
          .collection('gastos')
          .where('fixaId', isEqualTo: fixa.id)
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(fimMes))
          .limit(1)
          .get();

      if (existente.docs.isNotEmpty) continue;

      await firestore.collection('gastos').add({
        'descricao': data['descricao'],
        'valor': (data['valor'] as num?)?.toDouble() ?? 0.0,
        'categoria': data['categoria'] ?? 'Outros',
        'tipo':
            data['categoria'] ?? 'Outros', // mantém compatível com seu resumo
        'data': Timestamp.fromDate(dataLancamento),
        'fixaId': fixa.id,
        'origem': 'fixa',
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
  }
}
