import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _bancoFirebase = FirebaseFirestore.instance;

  Future<void> adicionarGanho(Map<String, dynamic> ganho) async {
    await _bancoFirebase.collection('ganhos').add(ganho);
  }

  Future<void> adicionarGasto(Map<String, dynamic> gasto) async {
    await _bancoFirebase.collection('gastos').add(gasto);
  }

  Stream<QuerySnapshot> listarGanhos() {
    return _bancoFirebase
        .collection('ganhos')
        .orderBy('data', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> listarGastos() {
    return _bancoFirebase
        .collection('gastos')
        .orderBy('data', descending: true)
        .snapshots();
  }
}
